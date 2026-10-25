/**
 * One refresh of one Live Activity session. Each refresh queues the next one
 * 30 seconds later as a Cloud Task, so nothing runs while nobody is following
 * a bus, and the chain ends itself at the session's deadline.
 */
import { endPayload, type LiveActivityPush, type PushResult, updatePayload } from "./apns";
import type { BusStopLineEstimation } from "./parser";
import { arrivalsChanged, buildSnapshot, staleDate } from "./snapshot";
import type { Session, SessionStore } from "./store";

export const REFRESH_INTERVAL_SECONDS = 30;
/** Never queue the next refresh sooner than this, even when running late. */
const MIN_DELAY_SECONDS = 5;
/** Treats a refresh this close to the deadline as the final one. */
const DEADLINE_TOLERANCE_SECONDS = 2;
/** How long APNs keeps retrying the final push to an offline device. */
const END_PUSH_EXPIRATION_SECONDS = 60 * 60;

export interface TickTask {
  sessionID: string;
  tick: number;
}

export interface TickDeps {
  sessions: SessionStore;
  /** Queues `task` to run at `runAt` (seconds); an already-queued task is fine. */
  schedule(task: TickTask, runAt: number): Promise<void>;
  estimations(stopID: number): Promise<BusStopLineEstimation[]>;
  push(push: LiveActivityPush): Promise<PushResult>;
  /** Seconds since 1970. */
  now(): number;
  log(message: string, details: Record<string, unknown>): void;
}

export type TickOutcome =
  | "missing"
  | "duplicate"
  | "ended"
  | "pushed"
  | "fetch-failed"
  | "token-invalid"
  | "push-failed";

/**
 * When refresh `tick` runs: a steady cadence from the session's creation,
 * with the last one exactly at the deadline to end the activity.
 */
export function tickTime(
  session: Pick<Session, "createdAt" | "endsAt">,
  tick: number,
  now: number,
): number {
  const due = Math.max(
    session.createdAt + tick * REFRESH_INTERVAL_SECONDS,
    now + MIN_DELAY_SECONDS,
  );
  return Math.min(due, session.endsAt);
}

export async function runTick(deps: TickDeps, task: TickTask): Promise<TickOutcome> {
  const session = await deps.sessions.get(task.sessionID);
  // Stopped or dismissed in the app: the chain ends here.
  if (!session) return "missing";
  if (task.tick <= session.lastTick) return "duplicate";

  const now = deps.now();
  if (now >= session.endsAt - DEADLINE_TOLERANCE_SECONDS) {
    if (!(await deps.sessions.claimTick(session.sessionID, task.tick))) return "duplicate";
    await endSession(deps, session, now);
    return "ended";
  }

  // Queue the next refresh before any work, so a failed fetch or push never
  // breaks the chain. If queueing itself fails, Cloud Tasks retries this one.
  const next = task.tick + 1;
  await deps.schedule({ sessionID: session.sessionID, tick: next }, tickTime(session, next, now));
  if (!(await deps.sessions.claimTick(session.sessionID, task.tick))) return "duplicate";

  let estimations: BusStopLineEstimation[];
  try {
    estimations = await deps.estimations(session.stopID);
  } catch (error) {
    // Push nothing: the activity shows its stale state 90 s after the last
    // successful fetch, as it does when the app's own refresh fails.
    deps.log("AUCORSA fetch failed", { sessionID: session.sessionID, error: String(error) });
    return "fetch-failed";
  }

  const snapshot = buildSnapshot(estimations, session.lineID, deps.now(), session.stopName);
  const stale = staleDate(snapshot, session.endsAt);
  const result = await deps.push({
    pushToken: session.pushToken,
    environment: session.apnsEnvironment,
    payload: updatePayload(snapshot, stale),
    // Changed minutes are worth an immediate update; a newer "Last updated"
    // alone is not worth spending the activity's high-priority budget on.
    priority: arrivalsChanged(session.lastState, snapshot) ? 10 : 5,
    expiration: stale,
  });

  if (result.outcome === "invalid-token") {
    deps.log("Push token rejected; ending session", { sessionID: session.sessionID, ...result });
    await deps.sessions.delete(session.sessionID);
    return "token-invalid";
  }
  if (result.outcome === "failed") {
    deps.log("Push failed", { sessionID: session.sessionID, ...result });
    return "push-failed";
  }

  await deps.sessions.saveState(session.sessionID, snapshot, deps.now());
  return "pushed";
}

/**
 * Ends the activity even while the app is suspended, which the app's own
 * deadline timer cannot guarantee.
 */
async function endSession(deps: TickDeps, session: Session, now: number): Promise<void> {
  const finalState =
    session.lastState ?? buildSnapshot([], session.lineID, now, session.stopName);
  const result = await deps.push({
    pushToken: session.pushToken,
    environment: session.apnsEnvironment,
    payload: endPayload(finalState, now),
    priority: 10,
    expiration: now + END_PUSH_EXPIRATION_SECONDS,
  });
  if (result.outcome !== "sent") {
    deps.log("End push failed", { sessionID: session.sessionID, ...result });
  }
  await deps.sessions.delete(session.sessionID);
}

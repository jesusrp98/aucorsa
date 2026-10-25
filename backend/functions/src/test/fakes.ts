import { readFileSync } from "node:fs";
import path from "node:path";
import type { LiveActivityPush, PushResult } from "../apns";
import type { BusArrivalSnapshot } from "../snapshot";
import type { NewSession, Session, SessionStore } from "../store";
import type { TickTask } from "../tick";

/** The Swift package's captured fixtures, shared so both ports agree. */
const FIXTURES = path.resolve(
  __dirname,
  "../../../../ios/AucorsaKit/Tests/AucorsaKitTests/Fixtures",
);

export function fixture(name: string): string {
  return readFileSync(path.join(FIXTURES, name), "utf8");
}

export const SESSION_ID = "0F4D2C6B-7A31-4E8B-9C55-2D1E6F8A9B03";
export const PUSH_TOKEN = "ab".repeat(80);
export const T0 = 1_800_000_000;

export function newSession(overrides: Partial<NewSession> = {}): NewSession {
  return {
    sessionID: SESSION_ID,
    pushToken: PUSH_TOKEN,
    apnsEnvironment: "sandbox",
    stopID: 105,
    lineID: "2",
    stopName: "Fátima",
    createdAt: T0,
    endsAt: T0 + 15 * 60,
    ...overrides,
  };
}

export class MemorySessionStore implements SessionStore {
  readonly sessions = new Map<string, Session>();

  async get(sessionID: string) {
    const session = this.sessions.get(sessionID);
    return session && structuredClone(session);
  }

  async create(session: NewSession) {
    if (this.sessions.has(session.sessionID)) return false;
    this.sessions.set(session.sessionID, {
      ...session,
      lastTick: 0,
      lastState: null,
      lastPushedAt: null,
    });
    return true;
  }

  async update(sessionID: string, fields: Partial<Session>) {
    const session = this.sessions.get(sessionID);
    if (!session) return false;
    Object.assign(session, fields);
    return true;
  }

  async delete(sessionID: string) {
    this.sessions.delete(sessionID);
  }

  async countActive(now: number) {
    return [...this.sessions.values()].filter((session) => session.endsAt > now).length;
  }

  async claimTick(sessionID: string, tick: number) {
    const session = this.sessions.get(sessionID);
    if (!session || session.lastTick >= tick) return false;
    session.lastTick = tick;
    return true;
  }

  async saveState(sessionID: string, state: BusArrivalSnapshot, pushedAt: number) {
    await this.update(sessionID, { lastState: state, lastPushedAt: pushedAt });
  }
}

/** Records scheduled tasks and pushes; time is controlled by the test. */
export class FakeWorld {
  readonly store = new MemorySessionStore();
  readonly scheduled: { task: TickTask; runAt: number }[] = [];
  readonly pushes: LiveActivityPush[] = [];
  readonly logs: string[] = [];
  clock = T0;
  pushResult: PushResult = { outcome: "sent", status: 200 };
  estimations: () => Promise<{ lineID: string; arrivals: number[] }[]> = async () => [
    { lineID: "1", arrivals: [12, 32] },
    { lineID: "2", arrivals: [1, 19] },
  ];

  readonly deps = {
    sessions: this.store,
    schedule: async (task: TickTask, runAt: number) => {
      this.scheduled.push({ task, runAt });
    },
    estimations: () => this.estimations(),
    push: async (push: LiveActivityPush) => {
      this.pushes.push(push);
      return this.pushResult;
    },
    now: () => this.clock,
    log: (message: string) => {
      this.logs.push(message);
    },
  };
}

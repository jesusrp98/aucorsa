/**
 * Firestore persistence. Apps never read or write Firestore directly
 * (`firestore.rules` denies everything); only these functions do.
 */
import {
  FieldValue,
  type DocumentReference,
  type Firestore,
  Timestamp,
} from "firebase-admin/firestore";
import type { ApnsEnvironment } from "./apns";
import type { BusArrivalSnapshot } from "./snapshot";

export const SESSIONS_COLLECTION = "liveActivitySessions";
const STATE_COLLECTION = "backendState";
/** Leftover sessions are deleted by a Firestore TTL policy on `expireAt`. */
const CLEANUP_AFTER_SECONDS = 60 * 60;

export interface Session {
  sessionID: string;
  pushToken: string;
  apnsEnvironment: ApnsEnvironment;
  stopID: number;
  lineID: string;
  stopName: string | null;
  /** Seconds since 1970; refreshes are scheduled every 30 s from here. */
  createdAt: number;
  /** Seconds since 1970; the session's hard deadline. */
  endsAt: number;
  /** The last refresh that started work, so duplicates are skipped. */
  lastTick: number;
  lastState: BusArrivalSnapshot | null;
  lastPushedAt: number | null;
}

export type NewSession = Omit<Session, "lastTick" | "lastState" | "lastPushedAt">;

export interface SessionStore {
  get(sessionID: string): Promise<Session | undefined>;
  /** Returns false when the session already exists. */
  create(session: NewSession): Promise<boolean>;
  /** Returns false when the session does not exist. */
  update(
    sessionID: string,
    fields: Partial<Pick<Session, "pushToken" | "apnsEnvironment" | "stopName">>,
  ): Promise<boolean>;
  delete(sessionID: string): Promise<void>;
  countActive(now: number): Promise<number>;
  /** Atomically records `tick` as started; false if it or a later one was. */
  claimTick(sessionID: string, tick: number): Promise<boolean>;
  saveState(sessionID: string, state: BusArrivalSnapshot, pushedAt: number): Promise<void>;
}

export class FirestoreSessionStore implements SessionStore {
  constructor(private readonly db: Firestore) {}

  private doc(sessionID: string) {
    return this.db.collection(SESSIONS_COLLECTION).doc(sessionID);
  }

  async get(sessionID: string): Promise<Session | undefined> {
    const snapshot = await this.doc(sessionID).get();
    if (!snapshot.exists) return undefined;
    const { expireAt: _expireAt, ...data } = snapshot.data()!;
    return { ...data, sessionID } as Session;
  }

  async create(session: NewSession): Promise<boolean> {
    const { sessionID, ...fields } = session;
    try {
      await this.doc(sessionID).create({
        ...fields,
        lastTick: 0,
        lastState: null,
        lastPushedAt: null,
        expireAt: Timestamp.fromMillis((session.endsAt + CLEANUP_AFTER_SECONDS) * 1000),
      });
      return true;
    } catch (error) {
      if (grpcCode(error) === ALREADY_EXISTS) return false;
      throw error;
    }
  }

  async update(
    sessionID: string,
    fields: Partial<Pick<Session, "pushToken" | "apnsEnvironment" | "stopName">>,
  ): Promise<boolean> {
    try {
      await this.doc(sessionID).update(fields);
      return true;
    } catch (error) {
      if (grpcCode(error) === NOT_FOUND) return false;
      throw error;
    }
  }

  async delete(sessionID: string): Promise<void> {
    await this.doc(sessionID).delete();
  }

  async countActive(now: number): Promise<number> {
    const result = await this.db
      .collection(SESSIONS_COLLECTION)
      .where("endsAt", ">", now)
      .count()
      .get();
    return result.data().count;
  }

  async claimTick(sessionID: string, tick: number): Promise<boolean> {
    const ref = this.doc(sessionID);
    return this.db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists || (snapshot.get("lastTick") as number) >= tick) return false;
      transaction.update(ref, { lastTick: tick });
      return true;
    });
  }

  async saveState(sessionID: string, state: BusArrivalSnapshot, pushedAt: number): Promise<void> {
    try {
      await this.doc(sessionID).update({ lastState: state, lastPushedAt: pushedAt });
    } catch (error) {
      // The app may end the session while a refresh is in flight.
      if (grpcCode(error) !== NOT_FOUND) throw error;
    }
  }
}

/**
 * A value cached in memory and shared through Firestore, so cold instances
 * reuse it: the AUCORSA nonce and the APNs provider token.
 */
export class SharedValueCache {
  private memory?: { value: string; storedAt: number };
  private readonly ref: DocumentReference;

  constructor(db: Firestore, name: string, private readonly ttlMs: number) {
    this.ref = db.collection(STATE_COLLECTION).doc(name);
  }

  async load(): Promise<string | undefined> {
    if (this.memory && this.isFresh(this.memory.storedAt)) return this.memory.value;
    const snapshot = await this.ref.get();
    const value = snapshot.get("value") as string | undefined;
    const storedAt = snapshot.get("storedAt") as number | undefined;
    if (!value || storedAt === undefined || !this.isFresh(storedAt)) return undefined;
    this.memory = { value, storedAt };
    return value;
  }

  async save(value: string): Promise<void> {
    this.memory = { value, storedAt: Date.now() };
    await this.ref.set(this.memory);
  }

  async invalidate(): Promise<void> {
    this.memory = undefined;
    await this.ref.set({ value: FieldValue.delete(), storedAt: FieldValue.delete() }, { merge: true });
  }

  private isFresh(storedAt: number): boolean {
    return Date.now() - storedAt < this.ttlMs;
  }
}

const ALREADY_EXISTS = 6;
const NOT_FOUND = 5;

function grpcCode(error: unknown): number | undefined {
  return (error as { code?: number }).code;
}

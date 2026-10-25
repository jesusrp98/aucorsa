/**
 * Runs against the Firestore emulator only: `npm run test:firestore`.
 * Skipped by plain `npm test`.
 */
import assert from "node:assert/strict";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { before, test } from "node:test";
import { SESSIONS_COLLECTION, FirestoreSessionStore, SharedValueCache } from "../store";
import { SESSION_ID, T0, newSession } from "./fakes";

const emulated = { skip: !process.env.FIRESTORE_EMULATOR_HOST && "needs the Firestore emulator" };

let store: FirestoreSessionStore;

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) return;
  initializeApp({ projectId: "demo-aucorsa" });
  const db = getFirestore();
  for (const doc of (await db.collection(SESSIONS_COLLECTION).get()).docs) await doc.ref.delete();
  store = new FirestoreSessionStore(db);
});

test("creates a session once, with a TTL timestamp", emulated, async () => {
  assert.equal(await store.create(newSession()), true);
  assert.equal(await store.create(newSession()), false);

  const session = await store.get(SESSION_ID);
  assert.equal(session?.lastTick, 0);
  assert.equal(session?.stopName, "Fátima");
  assert.equal("expireAt" in session!, false);

  const raw = await getFirestore().collection(SESSIONS_COLLECTION).doc(SESSION_ID).get();
  assert.equal(raw.get("expireAt").toMillis(), (T0 + 15 * 60 + 3600) * 1000);
});

test("claims each refresh only once, in order", emulated, async () => {
  assert.equal(await store.claimTick(SESSION_ID, 1), true);
  assert.equal(await store.claimTick(SESSION_ID, 1), false);
  assert.equal(await store.claimTick(SESSION_ID, 3), true);
  assert.equal(await store.claimTick(SESSION_ID, 2), false);
  assert.equal(await store.claimTick("missing", 1), false);
});

test("updates, counts, saves state, and deletes", emulated, async () => {
  assert.equal(await store.update(SESSION_ID, { stopName: null }), true);
  assert.equal(await store.update("missing", { stopName: null }), false);
  assert.equal(await store.countActive(T0), 1);
  assert.equal(await store.countActive(T0 + 15 * 60), 0);

  const state = { fetchedAt: T0, lines: [{ lineID: "2", arrivals: [1] }] };
  await store.saveState(SESSION_ID, state, T0 + 1);
  assert.deepEqual((await store.get(SESSION_ID))?.lastState, state);

  await store.delete(SESSION_ID);
  assert.equal(await store.get(SESSION_ID), undefined);
  // A refresh finishing after the app stopped the session is harmless.
  await store.saveState(SESSION_ID, state, T0 + 2);
});

test("shared values expire and can be invalidated", emulated, async () => {
  const cache = new SharedValueCache(getFirestore(), "testValue", 60_000);
  await cache.save("nonce");
  assert.equal(await new SharedValueCache(getFirestore(), "testValue", 60_000).load(), "nonce");
  assert.equal(await new SharedValueCache(getFirestore(), "testValue", 0).load(), undefined);
  await cache.invalidate();
  assert.equal(await cache.load(), undefined);
});

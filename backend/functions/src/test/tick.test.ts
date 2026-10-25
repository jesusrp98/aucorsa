import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";
import { runTick, tickTime } from "../tick";
import { FakeWorld, SESSION_ID, T0, newSession } from "./fakes";

let world: FakeWorld;

beforeEach(async () => {
  world = new FakeWorld();
  await world.store.create(newSession());
});

test("pushes the selected line first and queues the next refresh 30 s later", async () => {
  world.clock = T0 + 30.4;
  assert.equal(await runTick(world.deps, { sessionID: SESSION_ID, tick: 1 }), "pushed");

  assert.deepEqual(world.scheduled, [{ task: { sessionID: SESSION_ID, tick: 2 }, runAt: T0 + 60 }]);
  const [push] = world.pushes;
  assert.equal(push.priority, 10);
  assert.equal(push.environment, "sandbox");
  assert.deepEqual(push.payload, {
    aps: {
      timestamp: T0 + 30,
      event: "update",
      "content-state": {
        fetchedAt: T0 + 30.4,
        lines: [
          { lineID: "2", arrivals: [1, 19] },
          { lineID: "1", arrivals: [12, 32] },
        ],
        stopName: "Fátima",
      },
      "stale-date": T0 + 120,
    },
  });
  assert.equal(push.expiration, T0 + 120.4);
  assert.equal(world.store.sessions.get(SESSION_ID)?.lastTick, 1);
});

test("unchanged estimates refresh at low priority", async () => {
  world.clock = T0 + 30;
  await runTick(world.deps, { sessionID: SESSION_ID, tick: 1 });
  world.clock = T0 + 60;
  await runTick(world.deps, { sessionID: SESSION_ID, tick: 2 });
  assert.deepEqual(world.pushes.map((push) => push.priority), [10, 5]);
  assert.equal(world.pushes[1].payload.aps.timestamp, T0 + 60);
});

test("a duplicate delivery does no work twice", async () => {
  world.clock = T0 + 30;
  await runTick(world.deps, { sessionID: SESSION_ID, tick: 1 });
  assert.equal(await runTick(world.deps, { sessionID: SESSION_ID, tick: 1 }), "duplicate");
  assert.equal(world.pushes.length, 1);
});

test("a stopped session ends the chain", async () => {
  await world.store.delete(SESSION_ID);
  assert.equal(await runTick(world.deps, { sessionID: SESSION_ID, tick: 1 }), "missing");
  assert.equal(world.scheduled.length + world.pushes.length, 0);
});

test("a failed fetch pushes nothing but keeps the chain going", async () => {
  world.estimations = async () => {
    throw new Error("timeout");
  };
  world.clock = T0 + 30;
  assert.equal(await runTick(world.deps, { sessionID: SESSION_ID, tick: 1 }), "fetch-failed");
  assert.equal(world.pushes.length, 0);
  assert.equal(world.scheduled.length, 1);
});

test("a rejected push token deletes the session", async () => {
  world.pushResult = { outcome: "invalid-token", status: 410, reason: "Unregistered" };
  world.clock = T0 + 30;
  assert.equal(await runTick(world.deps, { sessionID: SESSION_ID, tick: 1 }), "token-invalid");
  assert.equal(world.store.sessions.has(SESSION_ID), false);
});

test("the deadline ends the activity immediately and deletes the session", async () => {
  world.clock = T0 + 30;
  await runTick(world.deps, { sessionID: SESSION_ID, tick: 1 });
  world.clock = T0 + 15 * 60;
  assert.equal(await runTick(world.deps, { sessionID: SESSION_ID, tick: 30 }), "ended");

  const end = world.pushes.at(-1)!;
  assert.equal(end.payload.aps.event, "end");
  assert.equal(end.payload.aps["dismissal-date"], T0 + 15 * 60);
  assert.deepEqual(end.payload.aps["content-state"], world.pushes[0].payload.aps["content-state"]);
  assert.equal(world.store.sessions.has(SESSION_ID), false);
  assert.equal(world.scheduled.length, 1);
});

test("refreshes keep a steady cadence and the last one lands on the deadline", () => {
  const session = { createdAt: T0, endsAt: T0 + 15 * 60 };
  assert.equal(tickTime(session, 2, T0 + 31), T0 + 60);
  // Running late: never queue the next one sooner than 5 s from now.
  assert.equal(tickTime(session, 2, T0 + 58), T0 + 63);
  assert.equal(tickTime(session, 30, T0 + 871), T0 + 900);
  assert.equal(tickTime(session, 31, T0 + 899), T0 + 900);
});

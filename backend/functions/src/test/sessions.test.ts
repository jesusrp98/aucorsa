import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";
import { MAX_ACTIVE_SESSIONS, handleSessionsRequest } from "../sessions";
import { FakeWorld, PUSH_TOKEN, SESSION_ID, T0, newSession } from "./fakes";

let world: FakeWorld;
const request = (method: string, body?: unknown, sessionID = SESSION_ID) =>
  handleSessionsRequest(world.deps, method, `/${sessionID}`, body);

const registration = {
  pushToken: PUSH_TOKEN.toUpperCase(),
  apnsEnvironment: "sandbox",
  stopID: 105,
  lineID: "2",
  stopName: "Fátima",
  endsAt: T0 + 15 * 60,
};

beforeEach(() => {
  world = new FakeWorld();
});

test("PUT starts a session and queues its first refresh", async () => {
  assert.deepEqual(await request("PUT", registration), { status: 201 });
  const session = world.store.sessions.get(SESSION_ID)!;
  assert.equal(session.pushToken, PUSH_TOKEN);
  assert.equal(session.endsAt, T0 + 15 * 60);
  assert.deepEqual(world.scheduled, [{ task: { sessionID: SESSION_ID, tick: 1 }, runAt: T0 + 30 }]);
});

test("PUT again updates a rotated token without a second refresh chain", async () => {
  await request("PUT", registration);
  const rotated = "cd".repeat(80);
  assert.deepEqual(await request("PUT", { ...registration, pushToken: rotated }), { status: 200 });
  assert.equal(world.store.sessions.get(SESSION_ID)?.pushToken, rotated);
  assert.equal(world.scheduled.length, 1);
});

test("the server caps sessions at 15 minutes", async () => {
  await request("PUT", { ...registration, endsAt: T0 + 3600 });
  assert.equal(world.store.sessions.get(SESSION_ID)?.endsAt, T0 + 15 * 60);
});

test("session IDs are case-insensitive", async () => {
  await request("PUT", registration, SESSION_ID.toLowerCase());
  assert.ok(world.store.sessions.has(SESSION_ID));
});

test("PUT rejects invalid registrations", async () => {
  const invalid = [
    { ...registration, pushToken: "not-hex" },
    { ...registration, apnsEnvironment: "staging" },
    { ...registration, stopID: "105" },
    { ...registration, lineID: "C2" },
    { ...registration, stopName: 42 },
    { ...registration, endsAt: T0 - 1 },
  ];
  for (const body of invalid) {
    assert.equal((await request("PUT", body)).status, 400, JSON.stringify(body));
  }
  assert.equal(world.store.sessions.size, 0);
});

test("unknown paths are not sessions", async () => {
  assert.equal((await request("PUT", registration, "not-a-uuid")).status, 404);
});

test("PUT refuses new sessions beyond the active limit", async () => {
  for (let index = 0; index < MAX_ACTIVE_SESSIONS; index++) {
    await world.store.create(newSession({ sessionID: `session-${index}` }));
  }
  assert.equal((await request("PUT", registration)).status, 429);
});

test("PUT reports and cleans up when the refresh can't be queued", async () => {
  world.deps.schedule = async () => {
    throw new Error("Cloud Tasks unavailable");
  };
  assert.equal((await request("PUT", registration)).status, 503);
  assert.equal(world.store.sessions.size, 0);
});

test("PATCH renames, and clears the name with null", async () => {
  await request("PUT", registration);
  assert.deepEqual(await request("PATCH", { stopName: "Casa" }), { status: 204 });
  assert.equal(world.store.sessions.get(SESSION_ID)?.stopName, "Casa");
  await request("PATCH", { stopName: null });
  assert.equal(world.store.sessions.get(SESSION_ID)?.stopName, null);
  assert.equal((await request("PATCH", { stopName: 1 })).status, 400);
});

test("PATCH on an unknown session is a 404", async () => {
  assert.equal((await request("PATCH", { stopName: "Casa" })).status, 404);
});

test("DELETE stops the session, and is idempotent", async () => {
  await request("PUT", registration);
  assert.deepEqual(await request("DELETE"), { status: 204 });
  assert.deepEqual(await request("DELETE"), { status: 204 });
  assert.equal(world.store.sessions.size, 0);
});

test("other methods are not allowed", async () => {
  assert.equal((await request("GET")).status, 405);
});

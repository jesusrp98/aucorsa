import assert from "node:assert/strict";
import { generateKeyPairSync, verify } from "node:crypto";
import http2 from "node:http2";
import type { AddressInfo } from "node:net";
import { after, before, test } from "node:test";
import {
  ApnsClient,
  type LiveActivityPush,
  type ProviderTokenCache,
  endPayload,
  providerToken,
  updatePayload,
} from "../apns";
import { buildSnapshot } from "../snapshot";
import { PUSH_TOKEN, T0 } from "./fakes";

const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
const credentials = {
  keyID: "ABC123DEFG",
  teamID: "TEAM123456",
  bundleID: "com.example.aucorsa",
  privateKey: privateKey.export({ type: "pkcs8", format: "pem" }).toString(),
};

/** A plaintext HTTP/2 stand-in for APNs that answers from `responses`. */
interface Received {
  headers: http2.IncomingHttpHeaders;
  body: string;
}
const received: Received[] = [];
let responses: { status: number; reason?: string }[] = [];
let server: http2.Http2Server;
let origin: string;

before(async () => {
  server = http2.createServer();
  server.on("stream", (stream, headers) => {
    let body = "";
    stream.setEncoding("utf8");
    stream.on("data", (chunk: string) => (body += chunk));
    stream.on("end", () => {
      received.push({ headers, body });
      const { status, reason } = responses.shift() ?? { status: 200 };
      stream.respond({ ":status": status });
      stream.end(reason ? JSON.stringify({ reason }) : undefined);
    });
  });
  await new Promise<void>((resolve) => server.listen(0, resolve));
  origin = `http://localhost:${(server.address() as AddressInfo).port}`;
});

after(() => server.close());

class MemoryTokenCache implements ProviderTokenCache {
  value?: string;
  invalidations = 0;
  async load() {
    return this.value;
  }
  async save(token: string) {
    this.value = token;
  }
  async invalidate() {
    this.value = undefined;
    this.invalidations++;
  }
}

const snapshot = buildSnapshot([{ lineID: "2", arrivals: [1, 19] }], "2", T0, "Fátima");
const push: LiveActivityPush = {
  pushToken: PUSH_TOKEN,
  environment: "sandbox",
  payload: updatePayload(snapshot, T0 + 90),
  priority: 10,
  expiration: T0 + 90,
};

function client(tokens = new MemoryTokenCache()) {
  return new ApnsClient(credentials, tokens, { sandbox: origin, production: "http://invalid" });
}

test("provider tokens are ES256 JWTs APNs can verify", () => {
  const token = providerToken(credentials, T0);
  const [header, claims, signature] = token.split(".");
  const decode = (part: string) => JSON.parse(Buffer.from(part, "base64url").toString());
  assert.deepEqual(decode(header), { alg: "ES256", kid: "ABC123DEFG" });
  assert.deepEqual(decode(claims), { iss: "TEAM123456", iat: T0 });
  assert.ok(
    verify(
      "sha256",
      Buffer.from(`${header}.${claims}`),
      { key: publicKey, dsaEncoding: "ieee-p1363" },
      Buffer.from(signature, "base64url"),
    ),
  );
});

test("sends a Live Activity update over HTTP/2", async () => {
  received.length = 0;
  const apns = client();
  assert.deepEqual(await apns.send(push), { outcome: "sent", status: 200, reason: undefined });
  apns.close();

  const [{ headers, body }] = received;
  assert.equal(headers[":method"], "POST");
  assert.equal(headers[":path"], `/3/device/${PUSH_TOKEN}`);
  assert.equal(headers["apns-push-type"], "liveactivity");
  assert.equal(headers["apns-topic"], "com.example.aucorsa.push-type.liveactivity");
  assert.equal(headers["apns-priority"], "10");
  assert.equal(headers["apns-expiration"], String(T0 + 90));
  assert.match(String(headers.authorization), /^bearer [\w-]+\.[\w-]+\.[\w-]+$/);
  assert.deepEqual(JSON.parse(body), {
    aps: {
      timestamp: T0,
      event: "update",
      "content-state": {
        fetchedAt: T0,
        lines: [{ lineID: "2", arrivals: [1, 19] }],
        stopName: "Fátima",
      },
      "stale-date": T0 + 90,
    },
  });
});

test("reuses one provider token across pushes", async () => {
  received.length = 0;
  const tokens = new MemoryTokenCache();
  const apns = client(tokens);
  await apns.send(push);
  await apns.send(push);
  apns.close();
  assert.equal(received[0].headers.authorization, received[1].headers.authorization);
  assert.equal(`bearer ${tokens.value}`, received[0].headers.authorization);
});

test("an expired provider token is replaced and the push retried once", async () => {
  received.length = 0;
  responses = [{ status: 403, reason: "ExpiredProviderToken" }, { status: 200 }];
  const tokens = new MemoryTokenCache();
  tokens.value = "stale.token.value";
  const apns = client(tokens);
  assert.equal((await apns.send(push)).outcome, "sent");
  apns.close();
  assert.equal(received[0].headers.authorization, "bearer stale.token.value");
  assert.notEqual(received[1].headers.authorization, "bearer stale.token.value");
  assert.equal(tokens.invalidations, 1);
});

test("ended activities and bad tokens are reported as invalid", async () => {
  responses = [
    { status: 410, reason: "Unregistered" },
    { status: 400, reason: "BadDeviceToken" },
    { status: 429, reason: "TooManyRequests" },
  ];
  const apns = client();
  assert.equal((await apns.send(push)).outcome, "invalid-token");
  assert.equal((await apns.send(push)).outcome, "invalid-token");
  assert.deepEqual(await apns.send(push), {
    outcome: "failed",
    status: 429,
    reason: "TooManyRequests",
  });
  apns.close();
});

test("an end push dismisses the activity immediately", () => {
  assert.deepEqual(endPayload(snapshot, T0 + 900).aps, {
    timestamp: T0 + 900,
    event: "end",
    "content-state": snapshot,
    "dismissal-date": T0 + 900,
  });
});

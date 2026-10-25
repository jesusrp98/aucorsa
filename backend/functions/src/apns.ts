/**
 * Sends ActivityKit pushes straight to APNs over HTTP/2, with token-based
 * (.p8) authentication. No Firebase Cloud Messaging is involved.
 *
 * https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications
 */
import { createPrivateKey, sign } from "node:crypto";
import http2 from "node:http2";
import type { BusArrivalSnapshot } from "./snapshot";

export type ApnsEnvironment = "sandbox" | "production";

const ORIGINS: Record<ApnsEnvironment, string> = {
  sandbox: "https://api.sandbox.push.apple.com",
  production: "https://api.push.apple.com",
};
const REQUEST_TIMEOUT_MS = 10_000;

/** Apple rejects tokens older than 60 minutes and updates more often than every 20. */
export const PROVIDER_TOKEN_TTL_MS = 50 * 60 * 1000;

export interface ApnsCredentials {
  keyID: string;
  teamID: string;
  /** The app's bundle ID; Live Activity pushes go to its own topic. */
  bundleID: string;
  /** The contents of the AuthKey_<keyID>.p8 file. */
  privateKey: string;
}

/** Where the signed provider token is shared between invocations. */
export interface ProviderTokenCache {
  load(): Promise<string | undefined>;
  save(token: string): Promise<void>;
  invalidate(): Promise<void>;
}

export type LiveActivityPayload = {
  aps: {
    timestamp: number;
    event: "update" | "end";
    "content-state": BusArrivalSnapshot;
    "stale-date"?: number;
    "dismissal-date"?: number;
  };
};

export interface LiveActivityPush {
  pushToken: string;
  environment: ApnsEnvironment;
  payload: LiveActivityPayload;
  /** 10 delivers immediately but spends the activity's budget; 5 doesn't. */
  priority: 5 | 10;
  /** Seconds since 1970 after which APNs should drop an undelivered push. */
  expiration: number;
}

export interface PushResult {
  /** `invalid-token`: the activity ended or the token is wrong; stop sending to it. */
  outcome: "sent" | "invalid-token" | "failed";
  status?: number;
  /** APNs' reason string, such as `BadDeviceToken`. */
  reason?: string;
}

export function updatePayload(
  snapshot: BusArrivalSnapshot,
  staleDate: number,
): LiveActivityPayload {
  return {
    aps: {
      timestamp: Math.floor(snapshot.fetchedAt),
      event: "update",
      "content-state": snapshot,
      "stale-date": Math.floor(staleDate),
    },
  };
}

/** Ends the activity and removes it from the Lock Screen right away. */
export function endPayload(
  snapshot: BusArrivalSnapshot,
  now: number,
): LiveActivityPayload {
  return {
    aps: {
      timestamp: Math.floor(now),
      event: "end",
      "content-state": snapshot,
      "dismissal-date": Math.floor(now),
    },
  };
}

const base64url = (value: Buffer | string) =>
  Buffer.from(value).toString("base64url");

/** An ES256 JWT, as APNs requires. */
export function providerToken(credentials: ApnsCredentials, issuedAt: number): string {
  const header = base64url(JSON.stringify({ alg: "ES256", kid: credentials.keyID }));
  const claims = base64url(
    JSON.stringify({ iss: credentials.teamID, iat: Math.floor(issuedAt) }),
  );
  const signature = sign("sha256", Buffer.from(`${header}.${claims}`), {
    key: createPrivateKey(credentials.privateKey),
    // JWTs carry the raw r||s signature, not DER.
    dsaEncoding: "ieee-p1363",
  });
  return `${header}.${claims}.${base64url(signature)}`;
}

export class ApnsClient {
  private readonly sessions = new Map<string, http2.ClientHttp2Session>();
  private cachedToken?: { token: string; issuedAt: number };

  constructor(
    private readonly credentials: ApnsCredentials,
    private readonly tokens: ProviderTokenCache,
    private readonly origins: Record<ApnsEnvironment, string> = ORIGINS,
  ) {}

  async send(push: LiveActivityPush): Promise<PushResult> {
    let response = await this.post(push, await this.token(false));
    // A stale shared token: sign a new one and try once more.
    if (
      response.status === 403 &&
      (response.reason === "ExpiredProviderToken" ||
        response.reason === "InvalidProviderToken")
    ) {
      response = await this.post(push, await this.token(true));
    }

    if (response.status === 200) return { outcome: "sent", ...response };
    if (
      response.status === 410 ||
      (response.status === 400 &&
        (response.reason === "BadDeviceToken" ||
          response.reason === "DeviceTokenNotForTopic"))
    ) {
      return { outcome: "invalid-token", ...response };
    }
    return { outcome: "failed", ...response };
  }

  close(): void {
    for (const session of this.sessions.values()) session.close();
    this.sessions.clear();
  }

  private async token(forceRefresh: boolean): Promise<string> {
    const now = Date.now();
    if (!forceRefresh) {
      if (this.cachedToken && now - this.cachedToken.issuedAt < PROVIDER_TOKEN_TTL_MS) {
        return this.cachedToken.token;
      }
      const shared = await this.tokens.load();
      if (shared) {
        this.cachedToken = { token: shared, issuedAt: issuedAtOf(shared) * 1000 };
        return shared;
      }
    } else {
      await this.tokens.invalidate();
    }

    const token = providerToken(this.credentials, now / 1000);
    this.cachedToken = { token, issuedAt: now };
    await this.tokens.save(token);
    return token;
  }

  private session(origin: string): http2.ClientHttp2Session {
    const existing = this.sessions.get(origin);
    if (existing && !existing.closed && !existing.destroyed) return existing;

    // APNs prefers one long-lived connection over one per request.
    const session = http2.connect(origin);
    const forget = () => {
      if (this.sessions.get(origin) === session) this.sessions.delete(origin);
    };
    session.on("close", forget);
    session.on("goaway", forget);
    session.on("error", forget);
    this.sessions.set(origin, session);
    return session;
  }

  private post(
    push: LiveActivityPush,
    token: string,
  ): Promise<{ status?: number; reason?: string }> {
    const body = JSON.stringify(push.payload);
    return new Promise((resolve) => {
      let request: http2.ClientHttp2Stream;
      try {
        request = this.session(this.origins[push.environment]).request({
          ":method": "POST",
          ":path": `/3/device/${push.pushToken}`,
          authorization: `bearer ${token}`,
          "apns-push-type": "liveactivity",
          "apns-topic": `${this.credentials.bundleID}.push-type.liveactivity`,
          "apns-priority": String(push.priority),
          "apns-expiration": String(Math.floor(push.expiration)),
          "content-type": "application/json",
        });
      } catch (error) {
        resolve({ reason: String(error) });
        return;
      }

      let status: number | undefined;
      let data = "";
      request.setEncoding("utf8");
      request.setTimeout(REQUEST_TIMEOUT_MS, () => request.close(http2.constants.NGHTTP2_CANCEL));
      request.on("response", (headers) => {
        status = Number(headers[":status"]);
      });
      request.on("data", (chunk: string) => {
        data += chunk;
      });
      // Only the first resolve counts, so an error wins over the close after it.
      request.on("error", (error) => resolve({ status, reason: String(error) }));
      request.on("close", () =>
        resolve({ status, reason: reasonOf(data) ?? (status ? undefined : "no response") }),
      );
      request.end(body);
    });
  }
}

function reasonOf(body: string): string | undefined {
  try {
    return (JSON.parse(body) as { reason?: string }).reason;
  } catch {
    return undefined;
  }
}

function issuedAtOf(token: string): number {
  try {
    const claims = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString());
    return typeof claims.iat === "number" ? claims.iat : 0;
  } catch {
    return 0;
  }
}

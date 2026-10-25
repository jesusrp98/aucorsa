/**
 * Talks to the AUCORSA endpoints the app already uses.
 *
 * Port of `ios/AucorsaKit/Sources/AucorsaKit/Networking/AucorsaClient.swift`.
 * Keep the two in step: the estimations endpoint needs a WordPress nonce
 * scraped from the homepage, and the origin sits behind Cloudflare.
 */
import { sortedEstimations } from "./catalog";
import { type BusStopLineEstimation, parseEstimations } from "./parser";

export const HOMEPAGE_URL = "https://aucorsa.es/";
const ESTIMATIONS_URL =
  "https://lightapi.aucorsa.es/wp-json/aucorsa/v1/estimations/stop";
const NONCE_PATTERN = /"ajax_nonce"\s*:\s*"([^"]+)"/;

// An explicit User-Agent is required, not cosmetic: Cloudflare rejects several
// default library agents with "error code: 1010" before reaching AUCORSA.
const USER_AGENT = "AucorsaGO/1.6.0 (server)";
const TIMEOUT_MS = 8_000;

// Upstream nonces live around 24 hours; a rejected one is caught by the 403
// retry anyway, so this only bounds how often the homepage is downloaded.
export const NONCE_TTL_MS = 6 * 60 * 60 * 1000;

export class AucorsaError extends Error {
  constructor(
    message: string,
    readonly status?: number,
  ) {
    super(message);
    this.name = "AucorsaError";
  }
}

export interface NonceCache {
  load(): Promise<string | undefined>;
  save(nonce: string): Promise<void>;
  invalidate(): Promise<void>;
}

/** Per-instance cache. Phase 1 swaps in a Firestore-backed one. */
export class MemoryNonceCache implements NonceCache {
  private value?: { nonce: string; storedAt: number };

  async load(): Promise<string | undefined> {
    if (!this.value || Date.now() - this.value.storedAt >= NONCE_TTL_MS) {
      return undefined;
    }
    return this.value.nonce;
  }

  async save(nonce: string): Promise<void> {
    this.value = { nonce, storedAt: Date.now() };
  }

  async invalidate(): Promise<void> {
    this.value = undefined;
  }
}

export function estimationsURL(stopID: number, nonce: string): string {
  const url = new URL(ESTIMATIONS_URL);
  url.searchParams.set("stop_id", String(stopID));
  url.searchParams.set("_wpnonce", nonce);
  return url.toString();
}

/**
 * A rejected nonce can also live in a proxy's cached homepage, so the single
 * recovery attempt uses a fresh URL instead of the same cached page.
 */
export function cacheBustedHomepageURL(): string {
  const url = new URL(HOMEPAGE_URL);
  url.searchParams.set("_aucorsa_nonce_refresh", crypto.randomUUID());
  return url.toString();
}

export function parseNonce(homepage: string): string | undefined {
  return NONCE_PATTERN.exec(homepage)?.[1];
}

/** WordPress's error code from a JSON error body, if there is one. */
export function apiErrorCode(body: string): string | undefined {
  try {
    const code = (JSON.parse(body) as { code?: unknown }).code;
    return typeof code === "string" ? code : undefined;
  } catch {
    return undefined;
  }
}

/**
 * The endpoint returns a JSON-encoded *string* whose value is the HTML
 * fragment, not raw HTML.
 */
export function decodeEstimationsBody(body: string): string | undefined {
  try {
    const value: unknown = JSON.parse(body);
    return typeof value === "string" ? value : undefined;
  } catch {
    return undefined;
  }
}

/**
 * Node's fetch keeps no cookie jar or HTTP cache, so every request is
 * anonymous and fresh, as the app's native client requires.
 */
export function aucorsaRequest(url: string): Promise<Response> {
  return fetch(url, {
    headers: {
      "User-Agent": USER_AGENT,
      Referer: HOMEPAGE_URL,
      "Cache-Control": "no-cache",
    },
    redirect: "follow",
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
}

export class AucorsaClient {
  constructor(private readonly nonces: NonceCache = new MemoryNonceCache()) {}

  /**
   * Arrival estimations for a stop, in the app's line display order. An empty
   * array is a valid answer: stops often have no service ("Sin estimaciones").
   */
  async estimations(stopID: number): Promise<BusStopLineEstimation[]> {
    return sortedEstimations(parseEstimations(await this.estimationsHTML(stopID)));
  }

  /** The estimations HTML fragment for a stop. */
  async estimationsHTML(stopID: number): Promise<string> {
    return this.fetchEstimations(stopID, true);
  }

  private async fetchEstimations(
    stopID: number,
    canRetry: boolean,
  ): Promise<string> {
    const nonce = await this.currentNonce(!canRetry);
    const response = await aucorsaRequest(estimationsURL(stopID, nonce));
    const body = await response.text();

    // An expired nonce reads as 403. Refresh once; a bounded retry keeps
    // this from looping when the service is simply rejecting us.
    if (response.status === 403 && canRetry) {
      await this.nonces.invalidate();
      return this.fetchEstimations(stopID, false);
    }
    if (response.status !== 200) {
      throw new AucorsaError(
        `Estimations failed (${apiErrorCode(body) ?? "non-JSON response"})`,
        response.status,
      );
    }

    const html = decodeEstimationsBody(body);
    if (html === undefined) {
      throw new AucorsaError("Unexpected estimations response", 200);
    }
    return html;
  }

  private async currentNonce(forceRefresh: boolean): Promise<string> {
    if (!forceRefresh) {
      const cached = await this.nonces.load();
      if (cached) return cached;
    }

    const response = await aucorsaRequest(
      forceRefresh ? cacheBustedHomepageURL() : HOMEPAGE_URL,
    );
    if (response.status !== 200) {
      throw new AucorsaError("Homepage unavailable", response.status);
    }
    const nonce = parseNonce(await response.text());
    if (!nonce) throw new AucorsaError("Nonce unavailable", 200);

    await this.nonces.save(nonce);
    return nonce;
  }
}

/**
 * Diagnoses whether this machine can reach AUCORSA, and what blocks it if
 * not. Phase 0 ran it from Cloud Functions in europe-west1; all stops passed.
 *
 * The result never includes the nonce, cookies, or response bodies.
 */
import {
  HOMEPAGE_URL,
  aucorsaRequest,
  apiErrorCode,
  cacheBustedHomepageURL,
  decodeEstimationsBody,
  estimationsURL,
  parseNonce,
} from "./aucorsa";

interface StepResult {
  status: number | null;
  ms: number;
  bytes: number;
  server?: string;
  /** The suffix names the Cloudflare data center that answered. */
  cfRay?: string;
  cfCacheStatus?: string;
  apiCode?: string;
  blockedBy?: string;
  error?: string;
}

export interface ProbeResult {
  verdict: "reachable" | "blocked" | "error";
  stopID: number;
  checkedAt: string;
  homepage: StepResult & { nonceFound: boolean };
  estimations?: StepResult & {
    retriedWithFreshNonce: boolean;
    noService?: boolean;
    lines?: string[];
  };
}

function blockedBy(status: number, body: string): string | undefined {
  if (body.includes("error code: 1010")) return "cloudflare-1010";
  if (/cf-chl|challenge-platform|Just a moment/i.test(body)) {
    return "cloudflare-challenge";
  }
  if (status === 429) return "rate-limited";
  return undefined;
}

async function step(url: string): Promise<{ result: StepResult; body: string }> {
  const started = performance.now();
  const elapsed = () => Math.round(performance.now() - started);
  try {
    const response = await aucorsaRequest(url);
    const body = await response.text();
    return {
      body,
      result: {
        status: response.status,
        ms: elapsed(),
        bytes: body.length,
        server: response.headers.get("server") ?? undefined,
        cfRay: response.headers.get("cf-ray") ?? undefined,
        cfCacheStatus: response.headers.get("cf-cache-status") ?? undefined,
        apiCode: response.status === 200 ? undefined : apiErrorCode(body),
        blockedBy: blockedBy(response.status, body),
      },
    };
  } catch (error) {
    return {
      body: "",
      result: { status: null, ms: elapsed(), bytes: 0, error: String(error) },
    };
  }
}

export async function runProbe(stopID: number): Promise<ProbeResult> {
  const checkedAt = new Date().toISOString();
  const homepage = await step(HOMEPAGE_URL);
  const nonce =
    homepage.result.status === 200 ? parseNonce(homepage.body) : undefined;
  const homepageResult = { ...homepage.result, nonceFound: nonce !== undefined };

  if (!nonce) {
    return {
      verdict: homepage.result.blockedBy ? "blocked" : "error",
      stopID,
      checkedAt,
      homepage: homepageResult,
    };
  }

  let estimations = await step(estimationsURL(stopID, nonce));
  let retriedWithFreshNonce = false;
  if (estimations.result.status === 403 && !estimations.result.blockedBy) {
    // Same single recovery attempt as the app: fresh homepage, one retry.
    const fresh = await step(cacheBustedHomepageURL());
    const freshNonce =
      fresh.result.status === 200 ? parseNonce(fresh.body) : undefined;
    if (freshNonce) {
      estimations = await step(estimationsURL(stopID, freshNonce));
      retriedWithFreshNonce = true;
    }
  }

  const html =
    estimations.result.status === 200
      ? decodeEstimationsBody(estimations.body)
      : undefined;
  const noService = html?.includes("ppp-no-estimations");
  const lines = html
    ? [...html.matchAll(/class="ppp-line-number"[^>]*>(.*?)<\/div>/gs)].map(
        (match) => match[1].trim(),
      )
    : undefined;
  const recognized = html !== undefined && (noService || lines!.length > 0);

  return {
    verdict: recognized
      ? "reachable"
      : estimations.result.blockedBy
        ? "blocked"
        : "error",
    stopID,
    checkedAt,
    homepage: homepageResult,
    estimations: {
      ...estimations.result,
      retriedWithFreshNonce,
      noService,
      lines,
    },
  };
}

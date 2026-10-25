import { createHash } from "node:crypto";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getFunctions } from "firebase-admin/functions";
import { logger } from "firebase-functions";
import { defineSecret, defineString } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { ApnsClient, PROVIDER_TOKEN_TTL_MS } from "./apns";
import { AucorsaClient, NONCE_TTL_MS } from "./aucorsa";
import { handleSessionsRequest } from "./sessions";
import { FirestoreSessionStore, SharedValueCache } from "./store";
import { runTick, type TickTask } from "./tick";

// europe-west1 is a Tier 1 region, so the full free allowance applies.
const REGION = "europe-west1";
setGlobalOptions({ region: REGION, maxInstances: 1 });
initializeApp();

// Set in functions/.env.<project ID>, which is not tracked; see .env.example.
const apnsKeyID = defineString("APNS_KEY_ID", {
  description: "Key ID of the APNs auth key (.p8) in the Apple Developer account",
});
const apnsTeamID = defineString("APNS_TEAM_ID", {
  description: "Apple Developer team ID that owns the APNs key",
});
const apnsBundleID = defineString("APNS_BUNDLE_ID", {
  description: "Bundle ID of the iOS app whose Live Activities receive pushes",
});
const apnsPrivateKey = defineSecret("APNS_PRIVATE_KEY");

const now = () => Date.now() / 1000;

// Built on first use: secrets are only readable at runtime, not at deploy.
let sessionStore: FirestoreSessionStore | undefined;
let aucorsa: AucorsaClient | undefined;
let apns: ApnsClient | undefined;

const sessions = () => (sessionStore ??= new FirestoreSessionStore(getFirestore()));

const aucorsaClient = () =>
  (aucorsa ??= new AucorsaClient(
    new SharedValueCache(getFirestore(), "aucorsaNonce", NONCE_TTL_MS),
  ));

const apnsClient = () =>
  (apns ??= new ApnsClient(
    {
      keyID: apnsKeyID.value(),
      teamID: apnsTeamID.value(),
      bundleID: apnsBundleID.value(),
      privateKey: apnsPrivateKey.value(),
    },
    new SharedValueCache(getFirestore(), "apnsProviderToken", PROVIDER_TOKEN_TTL_MS),
  ));

/**
 * Queues a refresh. Task IDs make a duplicate delivery unable to fork the
 * chain; Cloud Tasks wants them hashed rather than sequential.
 */
async function schedule(task: TickTask, runAt: number): Promise<void> {
  try {
    await getFunctions()
      .taskQueue<TickTask>(`locations/${REGION}/functions/liveActivityTick`)
      .enqueue(task, {
        scheduleTime: new Date(runAt * 1000),
        dispatchDeadlineSeconds: 30,
        id: createHash("sha256").update(`${task.sessionID}:${task.tick}`).digest("hex"),
      });
  } catch (error) {
    if ((error as { code?: string }).code === "functions/task-already-exists") return;
    throw error;
  }
}

export const liveActivitySessions = onRequest(
  { timeoutSeconds: 15, memory: "256MiB", maxInstances: 2 },
  async (request, response) => {
    const result = await handleSessionsRequest(
      { sessions: sessions(), schedule, now },
      request.method,
      request.path,
      request.body,
    );
    if (result.body) response.status(result.status).json(result.body);
    else response.status(result.status).end();
  },
);

export const liveActivityTick = onTaskDispatched<TickTask>(
  {
    secrets: [apnsPrivateKey],
    timeoutSeconds: 25,
    memory: "256MiB",
    // A failed refresh is not retried: the next one is already queued. Only
    // failing to queue it throws, and that is worth a quick retry.
    retryConfig: { maxAttempts: 3, minBackoffSeconds: 2, maxBackoffSeconds: 10 },
    // A refresh takes about a second, so one at a time covers many sessions.
    rateLimits: { maxConcurrentDispatches: 1 },
  },
  async (request) => {
    const outcome = await runTick(
      {
        sessions: sessions(),
        schedule,
        estimations: (stopID) => aucorsaClient().estimations(stopID),
        push: (push) => apnsClient().send(push),
        now,
        log: (message, details) => logger.warn(message, details),
      },
      request.data,
    );
    logger.info("Live Activity refresh", { ...request.data, outcome });
  },
);

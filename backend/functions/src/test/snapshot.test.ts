import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { test } from "node:test";
import catalogData from "../catalog.json";
import { servesStop, sortedEstimations } from "../catalog";
import { parseEstimations } from "../parser";
import { arrivalsChanged, buildSnapshot, snapshotLine, staleDate } from "../snapshot";
import { fixture } from "./fakes";

// Mirrors BusArrivalSnapshotTests.swift.

test("matches the content state the Swift app decodes", () => {
  const estimations = sortedEstimations(parseEstimations(fixture("estimations_populated.html")));
  const snapshot = buildSnapshot(estimations, "2", 1_800_000_000, "Fátima");
  // The same file is decoded by BusArrivalSnapshotTests.swift.
  assert.equal(
    JSON.stringify(snapshot),
    fixture("live_activity_content_state.json").trim(),
  );
});

test("estimations follow the app's line display order", () => {
  const sorted = sortedEstimations([
    { lineID: "unknown", arrivals: [] },
    { lineID: "2", arrivals: [] },
    { lineID: "1", arrivals: [] },
  ]);
  assert.deepEqual(sorted.map((line) => line.lineID), ["1", "2", "unknown"]);
});

test("selected line stays primary even when missing from the response", () => {
  const snapshot = buildSnapshot(
    [
      { lineID: "2", arrivals: [4, 8] },
      { lineID: "3", arrivals: [1] },
      { lineID: "4", arrivals: [2] },
    ],
    "1",
    1_800_000_000,
  );
  assert.deepEqual(snapshot.lines.map((line) => line.lineID), ["1", "2", "3"]);
  assert.deepEqual(snapshot.lines[0].arrivals, []);
  assert.equal("stopName" in snapshot, false);
});

test("retains only two valid arrivals per line", () => {
  assert.deepEqual(snapshotLine("1", [-1, 0, 8, 11, 9999]).arrivals, [0, 8]);
});

test("stop names are limited to 80 characters, counting emoji as one", () => {
  const snapshot = buildSnapshot([], "1", 1_800_000_000, "🏡".repeat(100));
  assert.equal(snapshot.stopName, "🏡".repeat(80));
});

test("freshness expires after 90 seconds or at the session end", () => {
  const snapshot = buildSnapshot([], "1", 1_800_000_000);
  assert.equal(staleDate(snapshot, 1_800_001_000), 1_800_000_090);
  assert.equal(staleDate(snapshot, 1_800_000_010), 1_800_000_010);
});

test("only changed estimates count as a change, not a newer fetch time", () => {
  const before = buildSnapshot([{ lineID: "1", arrivals: [3] }], "1", 1_800_000_000);
  const later = buildSnapshot([{ lineID: "1", arrivals: [3] }], "1", 1_800_000_030);
  const changed = buildSnapshot([{ lineID: "1", arrivals: [2] }], "1", 1_800_000_060);
  assert.equal(arrivalsChanged(null, before), true);
  assert.equal(arrivalsChanged(before, later), false);
  assert.equal(arrivalsChanged(later, changed), true);
});

test("validates lines against the stops they serve", () => {
  assert.equal(servesStop(105, "1"), true);
  assert.equal(servesStop(105, "2"), true);
  assert.equal(servesStop(105, "C2"), false);
  assert.equal(servesStop(999_999, "1"), false);
});

test("catalog.json is up to date with transit_data.json", async () => {
  const root = path.resolve(__dirname, "../../../..");
  const generator = path.join(root, "backend/functions/scripts/generate-catalog.mjs");
  const { deriveCatalog } = await import(pathToFileURL(generator).href);
  const transitData = JSON.parse(
    readFileSync(
      path.join(root, "ios/AucorsaKit/Sources/AucorsaKit/Resources/transit_data.json"),
      "utf8",
    ),
  );
  assert.deepEqual(deriveCatalog(transitData), catalogData, "Run `npm run catalog`");
});

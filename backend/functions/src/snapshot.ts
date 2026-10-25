/**
 * The Live Activity's content state, as the app decodes it.
 *
 * Port of `ios/AucorsaKit/Sources/AucorsaKit/Models/BusArrivalSnapshot.swift`.
 * The JSON keys and limits must match the Swift `Codable` type exactly:
 * `snapshot.test` and the Swift tests share `live_activity_content_state.json`.
 */
import type { BusStopLineEstimation } from "./parser";

export interface SnapshotLine {
  lineID: string;
  arrivals: number[];
}

export interface BusArrivalSnapshot {
  /** Seconds since 1970 of the last successful network response. */
  fetchedAt: number;
  lines: SnapshotLine[];
  stopName?: string;
}

const MAX_LINES = 3;
const MAX_ARRIVALS = 2;
const MAX_MINUTES = 1440;
const MAX_STOP_NAME = 80;
/** Estimates read as stale this long after their fetch. */
export const FRESHNESS_SECONDS = 90;

const graphemes = new Intl.Segmenter(undefined, { granularity: "grapheme" });

export function snapshotLine(lineID: string, arrivals: number[]): SnapshotLine {
  return {
    lineID,
    arrivals: arrivals
      .filter((minutes) => minutes >= 0 && minutes <= MAX_MINUTES)
      .slice(0, MAX_ARRIVALS),
  };
}

/** Swift truncates by characters, which are grapheme clusters. */
export function truncatedStopName(name: string | null | undefined): string | undefined {
  if (!name) return undefined;
  return [...graphemes.segment(name)]
    .slice(0, MAX_STOP_NAME)
    .map((segment) => segment.segment)
    .join("");
}

/**
 * The selected line always comes first, even when the response omits it,
 * followed by up to two other lines in the order given.
 */
export function buildSnapshot(
  estimations: BusStopLineEstimation[],
  preferredLineID: string,
  fetchedAt: number,
  stopName?: string | null,
): BusArrivalSnapshot {
  const preferred = estimations.find((line) => line.lineID === preferredLineID);
  const others = estimations.filter((line) => line.lineID !== preferredLineID);
  const lines = [
    snapshotLine(preferredLineID, preferred?.arrivals ?? []),
    ...others.map((line) => snapshotLine(line.lineID, line.arrivals)),
  ].slice(0, MAX_LINES);

  const name = truncatedStopName(stopName);
  return name === undefined ? { fetchedAt, lines } : { fetchedAt, lines, stopName: name };
}

export function staleDate(snapshot: BusArrivalSnapshot, endsAt: number): number {
  return Math.min(snapshot.fetchedAt + FRESHNESS_SECONDS, endsAt);
}

/** Whether the estimates differ, ignoring when they were fetched. */
export function arrivalsChanged(
  previous: BusArrivalSnapshot | null | undefined,
  next: BusArrivalSnapshot,
): boolean {
  return JSON.stringify(previous?.lines) !== JSON.stringify(next.lines);
}

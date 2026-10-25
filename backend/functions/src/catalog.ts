/**
 * Stop and line data the backend needs, generated from the app's
 * `transit_data.json` by `scripts/generate-catalog.mjs`.
 */
import catalogData from "./catalog.json";
import type { BusStopLineEstimation } from "./parser";

interface CatalogData {
  /** The app's line display order. */
  lineOrder: string[];
  linesByStop: Record<string, string[]>;
}

const catalog = catalogData as CatalogData;
const lineIndexByID = new Map(catalog.lineOrder.map((id, index) => [id, index]));

/** Mirrors the app's check before it starts an activity. */
export function servesStop(stopID: number, lineID: string): boolean {
  return catalog.linesByStop[String(stopID)]?.includes(lineID) ?? false;
}

/**
 * Sorts estimations into the app's line display order, unknown lines last,
 * matching `TransitCatalog.sorted` in Swift.
 */
export function sortedEstimations(
  estimations: BusStopLineEstimation[],
): BusStopLineEstimation[] {
  const index = (id: string) => lineIndexByID.get(id) ?? Number.MAX_SAFE_INTEGER;
  return [...estimations].sort((a, b) => index(a.lineID) - index(b.lineID));
}

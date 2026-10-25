/**
 * Parses the HTML fragment the estimations endpoint returns.
 *
 * Port of `ios/AucorsaKit/Sources/AucorsaKit/Networking/EstimationParser.swift`.
 * It is tied to the exact markup AUCORSA emits, so `parser.test` runs it
 * against the same captured fixtures as the Swift tests.
 *
 * A stop with no service returns `<div class="ppp-no-estimations">` and no
 * containers at all. That is a normal state, not a failure.
 */

export interface BusStopLineEstimation {
  lineID: string;
  /** Minutes until arrival, soonest first. */
  arrivals: number[];
}

const CONTAINER_SEPARATOR = '<div class="ppp-container">';
const LINE_NUMBER_PATTERN = /class="ppp-line-number"[^>]*>(.*?)<\/div>/s;
const ARRIVAL_PATTERN = /<strong\b[^>]*>(.*?)<\/strong>/gs;
/** Leading digits, matching the Dart `RegExp('^([0-9]*)')`. */
const MINUTES_PATTERN = /^\s*([0-9]+)/;

const ENTITIES: [string, string][] = [
  ["&amp;", "&"], ["&lt;", "<"], ["&gt;", ">"], ["&quot;", '"'],
  ["&#039;", "'"], ["&apos;", "'"], ["&nbsp;", " "],
  ["&aacute;", "á"], ["&eacute;", "é"], ["&iacute;", "í"],
  ["&oacute;", "ó"], ["&uacute;", "ú"], ["&ntilde;", "ñ"],
  ["&Aacute;", "Á"], ["&Eacute;", "É"], ["&Iacute;", "Í"],
  ["&Oacute;", "Ó"], ["&Uacute;", "Ú"], ["&Ntilde;", "Ñ"],
];

export function parseEstimations(html: string): BusStopLineEstimation[] {
  // Splitting on the container marker is more robust than matching balanced
  // <div>s, and the marker never appears in stop or line names.
  return html
    .split(CONTAINER_SEPARATOR)
    .slice(1)
    .flatMap((block) => {
      const rawID = LINE_NUMBER_PATTERN.exec(block)?.[1];
      const lineID = rawID === undefined ? "" : decodeEntities(rawID).trim();
      if (!lineID) return [];

      const arrivals = [...block.matchAll(ARRIVAL_PATTERN)]
        .map((match) => minutesFrom(match[1]))
        .filter((minutes): minutes is number => minutes !== undefined);
      return [{ lineID, arrivals }];
    });
}

/**
 * `"3 minutos"` -> `3`. AUCORSA marks imminent buses as
 * `<strong class="blinker">ahora</strong>`; unknown text must not imply arrival.
 */
export function minutesFrom(text: string): number | undefined {
  const decoded = decodeEntities(text).trim();
  if (decoded.toLowerCase() === "ahora") return 0;
  const match = MINUTES_PATTERN.exec(decoded);
  return match ? Number(match[1]) : undefined;
}

export function decodeEntities(value: string): string {
  if (!value.includes("&")) return value;
  return ENTITIES.reduce(
    (result, [entity, replacement]) => result.replaceAll(entity, replacement),
    value,
  );
}

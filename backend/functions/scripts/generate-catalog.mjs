// Derives the backend's stop/line catalog from the app's generated
// `transit_data.json`. Run after `tools/update_transit_data.py`:
// `npm run catalog`. `catalog.test` fails when this output is stale.
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const source = fileURLToPath(new URL(
  "../../../ios/AucorsaKit/Sources/AucorsaKit/Resources/transit_data.json",
  import.meta.url,
));
const output = fileURLToPath(new URL("../src/catalog.json", import.meta.url));

export function deriveCatalog(transitData) {
  const linesByStop = {};
  for (const line of transitData.lines) {
    for (const stopID of line.stops) {
      (linesByStop[stopID] ??= []).push(line.id);
    }
  }
  // `lines` is already in the app's display order, which estimations sort by.
  return { lineOrder: transitData.lines.map((line) => line.id), linesByStop };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const catalog = deriveCatalog(JSON.parse(readFileSync(source, "utf8")));
  writeFileSync(output, `${JSON.stringify(catalog)}\n`);
  console.log(`Wrote ${output}`);
}

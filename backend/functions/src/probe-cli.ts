/** Local baseline: `npm run probe -- 105`. */
import { runProbe } from "./probe";

const stopID = Number(process.argv[2] ?? 105);

runProbe(stopID).then((result) => {
  console.log(JSON.stringify(result, null, 2));
  process.exitCode = result.verdict === "reachable" ? 0 : 1;
});

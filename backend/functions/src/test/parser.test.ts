import assert from "node:assert/strict";
import { test } from "node:test";
import { decodeEntities, minutesFrom, parseEstimations } from "../parser";
import { fixture } from "./fakes";

// Mirrors EstimationParserTests.swift, against the same captured fixtures.

test("parses a stop served by two lines", () => {
  const estimations = parseEstimations(fixture("estimations_populated.html"));
  assert.deepEqual(estimations, [
    { lineID: "2", arrivals: [1, 19] },
    { lineID: "1", arrivals: [12, 32] },
  ]);
});

test("a stop with no service parses to an empty result, not an error", () => {
  const html = fixture("estimations_empty.html");
  assert.ok(html.includes("ppp-no-estimations"));
  assert.deepEqual(parseEstimations(html), []);
});

test("garbage input yields nothing rather than throwing", () => {
  assert.deepEqual(parseEstimations(""), []);
  assert.deepEqual(parseEstimations("<html><body>nope</body></html>"), []);
});

test("minute extraction matches the Dart leading-digits rule", () => {
  assert.equal(minutesFrom("3 minutos"), 3);
  assert.equal(minutesFrom("1 minuto"), 1);
  assert.equal(minutesFrom("21 minutos"), 21);
  assert.equal(minutesFrom("  7 minutos"), 7);
});

test("non-numeric estimates are dropped, not reported as zero", () => {
  assert.equal(minutesFrom("En parada"), undefined);
  assert.equal(minutesFrom(""), undefined);
});

test("an arriving bus is retained before the later bus", () => {
  const parsed = parseEstimations(fixture("estimations_arriving_now.html"));
  assert.deepEqual(parsed[0], { lineID: "1", arrivals: [0, 19] });
  assert.equal(minutesFrom(" AHORA "), 0);
});

test("letter line ids survive parsing", () => {
  const html =
    '<div class="ppp-container"><div class="ppp-line-number" style="x">O1</div>' +
    '<div class="ppp-estimation"><span>Pr&oacute;ximo: <strong>4 minutos</strong></span></div></div>';
  assert.deepEqual(parseEstimations(html), [{ lineID: "O1", arrivals: [4] }]);
});

test("HTML entities decode", () => {
  assert.equal(decodeEntities("Pr&oacute;ximo"), "Próximo");
  assert.equal(decodeEntities("A&ntilde;adir"), "Añadir");
  assert.equal(decodeEntities("plain"), "plain");
});

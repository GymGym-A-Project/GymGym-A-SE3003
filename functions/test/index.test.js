const test = require("node:test");
const assert = require("node:assert");
const { _internal } = require("../index.js");

const { anonymize, filterToWhitelist, buildPrompt, explainPlateau } = _internal;

function mockGemini(payload, delayMs = 0) {
  global.fetch = (url, { signal }) =>
    new Promise((resolve, reject) => {
      const timer = setTimeout(
        () =>
          resolve({
            ok: true,
            json: async () => ({
              candidates: [{ content: { parts: [{ text: JSON.stringify(payload) }] } }],
            }),
          }),
        delayMs,
      );
      signal.addEventListener("abort", () => {
        clearTimeout(timer);
        reject(signal.reason);
      });
    });
}

test("anonymize drops uid, name and email", () => {
  const out = anonymize({ uid: "u1", name: "A", email: "a@b.c", sessions: 4 });
  assert.deepStrictEqual(out, { sessions: 4 });
});

test("prompt contains no personal data", () => {
  const prompt = buildPrompt(anonymize({ email: "a@b.c", sessions: 4 }), ["0025"]);
  assert.ok(!prompt.includes("a@b.c"));
});

test("whitelist keeps only the 152 known IDs", () => {
  assert.deepStrictEqual(filterToWhitelist(["0025", "9999", 42, "0030"]), ["0025", "0030"]);
});

test("IDs returned by Gemini outside the list are dropped", async () => {
  mockGemini({ explanation: "Plateau.", alternatives: ["0030", "9999", "hack"] });
  const res = await explainPlateau({ summary: {}, allowedExerciseIds: ["0030"] }, "key");
  assert.strictEqual(res.source, "gemini");
  assert.deepStrictEqual(res.alternatives, ["0030"]);
  assert.deepStrictEqual(res.droppedIds, ["9999", "hack"]);
});

test("falls back after the 4 s timeout", async () => {
  mockGemini({ explanation: "late", alternatives: [] }, 6000);
  const started = Date.now();
  const res = await explainPlateau({ summary: {} }, "key");
  const elapsed = Date.now() - started;
  assert.strictEqual(res.source, "fallback");
  assert.strictEqual(res.reason, "timeout");
  assert.ok(elapsed >= 3900 && elapsed < 5000, `elapsed ${elapsed} ms`);
  console.log(`timeout fallback after ${elapsed} ms`);
});

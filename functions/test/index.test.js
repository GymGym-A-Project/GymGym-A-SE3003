const test = require("node:test");
const assert = require("node:assert/strict");
const { anonymize, filterToWhitelist, buildPrompt, explainPlateau, DISCLAIMER } = require("../plateau_proxy");
const { _internal: { createHandler } } = require("../index");
const catalog = require("../../assets/data/exercises.json").exercises;
const ids = require("../exercise_ids.json");
const request = () => ({ summary: { exercises: [
  { exerciseId: "0025", sessions: [{ maxWeightKg: 60, totalVolume: 480 }] },
] }, allowedExerciseIds: ["0030", "0033", "0003"] });
const response = (ai, finishReason = "STOP") => ({ ok: true, json: async () => ({
  candidates: [{ finishReason, content: { parts: [{ text: JSON.stringify(ai) }] } }],
}) });
const good = { explanation: "Your recent metrics have remained similar.", alternatives: ["0030", "0033"] };

test("whitelist exactly matches the 152 catalog IDs without duplicates", () => {
  assert.equal(ids.length, 152);
  assert.equal(new Set(ids).size, 152);
  assert.deepEqual([...ids].sort(), catalog.map((e) => e.id).sort());
});

test("projection removes nested PII and all arbitrary strings without mutating input", () => {
  const input = request();
  input.summary.uid = "private-user";
  input.summary.exercises[0].name = "private-name";
  input.summary.exercises[0].sessions[0].metadata = { email: "private@example.com" };
  input.summary.exercises[0].sessions[0].notes = "private-free-text";
  input.summary.exercises[0].sessions[0].totalVolume = 480;
  const snapshot = JSON.stringify(input);
  const prompt = buildPrompt(input.summary, input.allowedExerciseIds);
  assert(!prompt.includes("private"));
  assert(prompt.includes('"totalVolume":480'));
  assert.equal(JSON.stringify(input), snapshot);
  assert.deepEqual(anonymize({ sessions: "private" }), { exercises: [] });
});

test("non-numeric, negative, non-finite metrics and unknown IDs are excluded", () => {
  const input = request().summary;
  input.exercises[0].sessions.push(null, { maxWeightKg: "private", totalVolume: 10 },
    { maxWeightKg: -1, totalVolume: 1 }, { maxWeightKg: 1, totalVolume: Infinity });
  input.exercises.push({ exerciseId: "private", sessions: [] });
  assert.equal(anonymize(input).exercises.length, 1);
  assert.equal(anonymize(input).exercises[0].sessions.length, 1);
  assert.deepEqual(filterToWhitelist(["0030", "0030", 42, "9999"]), ["0030"]);
});

test("Gemini receives only anonymous metrics; key stays in header", async () => {
  let sent;
  const result = await explainPlateau(request(), "secret-key", { fetchImpl: async (url, init) => {
    sent = { url, init };
    const reply = response(good);
    const data = await reply.json();
    data.candidates[0].content.parts.unshift({ thought: true, text: "internal reasoning" });
    return { ok: true, json: async () => data };
  } });
  assert.equal(result.source, "gemini");
  assert.equal(result.disclaimer, DISCLAIMER);
  assert(!sent.url.includes("secret-key"));
  assert(!sent.init.body.includes("secret-key"));
  assert.equal(sent.init.headers["x-goog-api-key"], "secret-key");
  assert(sent.init.signal instanceof AbortSignal);
});

test("unknown, unrequested, current and duplicate alternatives cannot escape", async () => {
  const result = await explainPlateau(request(), "key", { fetchImpl: async () => response({
    ...good, alternatives: ["0025", "9999", "0026", "0030", "0030", "0033"],
  }) });
  assert.deepEqual(result.alternatives, ["0030", "0033"]);
  assert(!("droppedIds" in result));
});

test("missing key and invalid input never call the upstream", async () => {
  const options = { fetchImpl: () => assert.fail("must not call Gemini") };
  assert.equal((await explainPlateau(request(), "", options)).reason, "missing_key");
  for (const body of [null, {}, [], { summary: null }, { ...request(), allowedExerciseIds: ["0030"] }]) {
    assert.equal((await explainPlateau(body, "key", options)).reason, "invalid_input");
  }
});

test("HTTP errors, rejected fetch, malformed JSON and blocked/truncated output fall back", async () => {
  const transports = [
    async () => ({ ok: false }),
    async () => { throw new Error("sensitive upstream details"); },
    async () => ({ ok: true, json: async () => { throw new Error("bad JSON"); } }),
    async () => response(good, "SAFETY"),
    async () => response(good, "MAX_TOKENS"),
    async () => ({ ok: true, json: async () => ({}) }),
  ];
  for (const fetchImpl of transports) {
    const result = await explainPlateau(request(), "key", { fetchImpl });
    assert.equal(result.source, "fallback");
    assert.deepEqual(result.alternatives, request().allowedExerciseIds);
    assert.equal(result.disclaimer, DISCLAIMER);
    assert(!JSON.stringify(result).includes("sensitive"));
  }
});

test("invalid schema or fewer than two verified suggestions uses deterministic fallback", async () => {
  for (const ai of [null, [], {}, { ...good, explanation: {} }, { ...good, explanation: " " },
    { ...good, alternatives: ["9999"] }, { ...good, explanation: "x".repeat(2001) }]) {
    const result = await explainPlateau(request(), "key", { fetchImpl: async () => response(ai) });
    assert.equal(result.source, "fallback");
    assert.equal(result.reason, "invalid_response");
    assert.equal(result.disclaimer, DISCLAIMER);
  }
});

test("deadline aborts a stuck body reader at 4 seconds even when transport ignores abort", async () => {
  let signal;
  const started = Date.now();
  const result = await explainPlateau(request(), "key", { fetchImpl: async (_, init) => {
    signal = init.signal;
    return { ok: true, json: () => new Promise(() => {}) };
  } });
  const elapsed = Date.now() - started;
  assert.equal(result.reason, "timeout");
  assert(signal.aborted);
  assert(elapsed >= 3900 && elapsed < 5000, `elapsed ${elapsed} ms`);
});

function httpRequest(overrides = {}) {
  return { method: "POST", body: request(), is: () => true,
    get: () => "Bearer token", ...overrides };
}
function httpResponse() {
  return { code: 200, headers: {}, set(k, v) { this.headers[k] = v; },
    status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } };
}
test("HTTP boundary rejects method, content type, oversized and unauthenticated requests", async () => {
  const handler = createHandler({ verifyToken: async () => { throw new Error("bad token"); },
    explain: () => assert.fail("must not invoke model"), key: () => "key", modelName: () => "model" });
  for (const [req, status] of [
    [httpRequest({ method: "GET" }), 405], [httpRequest({ is: () => false }), 415],
    [httpRequest({ body: { data: "x".repeat(33000) } }), 413],
    [httpRequest({ get: () => undefined }), 401], [httpRequest(), 401],
  ]) {
    const res = httpResponse();
    await handler(req, res);
    assert.equal(res.code, status);
    assert.equal(res.headers["Cache-Control"], "no-store");
  }
});
test("HTTP authorization is separate from prompt data and response includes disclaimer", async () => {
  const handler = createHandler({ verifyToken: async (token) => {
    assert.equal(token, "token"); return { uid: "never-forward-this" };
  }, explain: (body, key, options) => {
    assert(!JSON.stringify(body).includes("never-forward-this"));
    assert.equal(options.model, "gemini-2.5-flash");
    return explainPlateau(body, key);
  }, key: () => "", modelName: () => "gemini-2.5-flash" });
  const res = httpResponse();
  await handler(httpRequest(), res);
  assert.equal(res.code, 200);
  assert.equal(res.body.reason, "missing_key");
  assert.equal(res.body.disclaimer, DISCLAIMER);
  assert(Number.isFinite(res.body.elapsedMs));
});

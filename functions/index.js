/**
 * Week 3 spike: plateau explanation proxy for Gemini.
 *
 * - The model name lives in a single constant.
 * - Personal data (name, e-mail, uid) is dropped before building the prompt;
 *   only an anonymous workout summary and the allowed exercise IDs are sent.
 * - Returned exercise IDs are filtered against the 152-ID whitelist.
 * - Gemini gets 4 s; on timeout or any error a fallback message is returned.
 */
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const EXERCISE_IDS = new Set(require("./exercise_ids.json"));

const MODEL_NAME = "gemini-2.5-flash";
const TIMEOUT_MS = 4000;
const PII_FIELDS = ["uid", "name", "displayName", "email"];
const FALLBACK = {
  source: "fallback",
  explanation:
    "AI explanation is unavailable right now. Your rule-based plateau " +
    "result is still valid; try one of the suggested alternatives.",
  alternatives: [],
};

function anonymize(body) {
  const clean = { ...body };
  for (const field of PII_FIELDS) delete clean[field];
  return clean;
}

function filterToWhitelist(ids) {
  if (!Array.isArray(ids)) return [];
  return ids.filter((id) => typeof id === "string" && EXERCISE_IDS.has(id));
}

function buildPrompt(summary, allowedIds) {
  return [
    "You are a strength training assistant. Advisory only, not medical advice.",
    "A rule engine detected a plateau. Explain likely causes in 2-3 sentences",
    "and suggest up to 3 alternative exercises.",
    "Only use exercise IDs from this list:",
    JSON.stringify(allowedIds),
    "Workout summary (anonymous):",
    JSON.stringify(summary),
    'Reply as JSON: {"explanation": string, "alternatives": [exerciseId]}',
  ].join("\n");
}

async function callGemini(prompt, apiKey, timeoutMs = TIMEOUT_MS) {
  const url =
    "https://generativelanguage.googleapis.com/v1beta/models/" +
    `${MODEL_NAME}:generateContent`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { responseMimeType: "application/json" },
    }),
    signal: AbortSignal.timeout(timeoutMs),
  });
  if (!res.ok) throw new Error(`Gemini HTTP ${res.status}`);
  const data = await res.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
  return JSON.parse(text);
}

async function explainPlateau(body, apiKey) {
  const summary = anonymize(body.summary ?? {});
  const allowedIds = filterToWhitelist(body.allowedExerciseIds);
  if (!apiKey) return { ...FALLBACK, reason: "missing GEMINI_API_KEY" };

  try {
    const ai = await callGemini(buildPrompt(summary, allowedIds), apiKey);
    const requested = Array.isArray(ai.alternatives) ? ai.alternatives : [];
    const alternatives = filterToWhitelist(requested);
    return {
      source: "gemini",
      model: MODEL_NAME,
      explanation: String(ai.explanation ?? ""),
      alternatives,
      droppedIds: requested.filter((id) => !alternatives.includes(id)),
    };
  } catch (err) {
    logger.warn("Gemini call failed, using fallback", { error: err.message });
    return { ...FALLBACK, reason: err.name === "TimeoutError" ? "timeout" : "error" };
  }
}

exports.explainPlateau = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "POST only" });
    return;
  }
  const started = Date.now();
  const result = await explainPlateau(req.body ?? {}, process.env.GEMINI_API_KEY);
  res.json({ ...result, elapsedMs: Date.now() - started });
});

// Exposed for local checks.
exports._internal = { anonymize, filterToWhitelist, buildPrompt, explainPlateau };

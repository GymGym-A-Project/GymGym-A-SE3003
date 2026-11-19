// Allowlist projection: only known exercise IDs and numeric metrics cross this boundary.
const EXERCISE_IDS = new Set(require("./exercise_ids.json"));
const DISCLAIMER = "Advisory only - not medical or coaching advice";
const TIMEOUT_MS = 4000;
const FALLBACK_TEXT = "AI explanation is unavailable right now. Your rule-based plateau result is unchanged. Review your recent training and use the library alternatives below.";
const isObject = (v) => v !== null && typeof v === "object" && !Array.isArray(v);

function filterToWhitelist(ids) {
  return Array.isArray(ids)
    ? [...new Set(ids.filter((id) => typeof id === "string" && EXERCISE_IDS.has(id)))]
    : [];
}

function anonymize(summary) {
  if (!isObject(summary) || !Array.isArray(summary.exercises)) return { exercises: [] };
  const exercises = [];
  for (const exercise of summary.exercises.slice(0, 15)) {
    if (!isObject(exercise) || !EXERCISE_IDS.has(exercise.exerciseId) || !Array.isArray(exercise.sessions)) continue;
    const sessions = exercise.sessions.slice(-60).filter((s) =>
      isObject(s) && Number.isFinite(s.maxWeightKg) && s.maxWeightKg >= 0 &&
      s.maxWeightKg <= 10000 && Number.isFinite(s.totalVolume) &&
      s.totalVolume >= 0 && s.totalVolume <= 100000000,
    ).map((s) => ({ maxWeightKg: s.maxWeightKg, totalVolume: s.totalVolume }));
    if (sessions.length) exercises.push({ exerciseId: exercise.exerciseId, sessions });
  }
  return { exercises };
}

function buildPrompt(summary, allowedIds) {
  return [
    "Explain a plateau already detected by a deterministic rule engine in 2-3 short sentences.",
    DISCLAIMER,
    "Do not diagnose, prescribe, claim certainty or change the rule result.",
    "Suggest 2-3 alternative exercise IDs from the allowed list only.",
    JSON.stringify({ summary: anonymize(summary), allowedExerciseIds: filterToWhitelist(allowedIds) }),
    'Reply as JSON: {"explanation": string, "alternatives": [exerciseId]}',
  ].join("\n");
}

async function callGemini(prompt, apiKey, { signal, model, fetchImpl }) {
  if (!/^gemini-[a-z0-9.-]+$/.test(model)) throw new Error("invalid model");
  const response = await fetchImpl(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      signal,
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: "application/json", maxOutputTokens: 512 },
      }),
    },
  );
  if (!response.ok) throw new Error("upstream failure");
  const data = await response.json();
  const candidate = data?.candidates?.[0];
  if (candidate?.finishReason !== "STOP") throw new Error("incomplete response");
  return JSON.parse(candidate.content?.parts?.filter((p) => !p.thought).map((p) => p.text ?? "").join(""));
}

async function explainPlateau(body, apiKey, options = {}) {
  const summary = anonymize(body?.summary);
  const currentIds = new Set(summary.exercises.map((e) => e.exerciseId));
  const allowed = filterToWhitelist(body?.allowedExerciseIds).filter((id) => !currentIds.has(id));
  const fallback = (reason) => ({
    source: "fallback", reason, explanation: FALLBACK_TEXT,
    alternatives: allowed.slice(0, 3), disclaimer: DISCLAIMER,
  });
  if (!summary.exercises.length || allowed.length < 2) return fallback("invalid_input");
  if (!apiKey) return fallback("missing_key");
  const controller = new AbortController();
  let timer;
  try {
    // Includes response decoding and bounds transports that ignore abort.
    const deadline = new Promise((_, reject) => {
      timer = setTimeout(() => {
        controller.abort();
        reject(new Error("deadline"));
      }, TIMEOUT_MS);
    });
    const ai = await Promise.race([
      callGemini(buildPrompt(summary, allowed), apiKey, {
        signal: controller.signal,
        model: options.model ?? "gemini-2.5-flash",
        fetchImpl: options.fetchImpl ?? fetch,
      }),
      deadline,
    ]);
    if (!isObject(ai) || typeof ai.explanation !== "string" ||
        !ai.explanation.trim() || ai.explanation.length > 2000) return fallback("invalid_response");
    const alternatives = filterToWhitelist(ai.alternatives).filter((id) => allowed.includes(id)).slice(0, 3);
    if (alternatives.length < 2) return fallback("invalid_response");
    return {
      source: "gemini", explanation: ai.explanation.trim(), alternatives,
      disclaimer: DISCLAIMER,
    };
  } catch {
    return fallback(controller.signal.aborted ? "timeout" : "upstream_error");
  } finally {
    clearTimeout(timer);
  }
}

module.exports = { anonymize, filterToWhitelist, buildPrompt, explainPlateau, DISCLAIMER, TIMEOUT_MS };

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { getApps, initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const proxy = require("./plateau_proxy");
const apiKey = defineSecret("GEMINI_API_KEY");
const model = defineString("GEMINI_MODEL", { default: "gemini-2.5-flash" });

// UID authorizes the request; it is never passed to the prompt or logged.
function createHandler({ verifyToken, explain, key, modelName }) {
  return async (req, res) => {
    res.set("Cache-Control", "no-store");
    const reject = (status, error) => res.status(status).json({ error, disclaimer: proxy.DISCLAIMER });
    if (req.method !== "POST") {
      res.set("Allow", "POST");
      return reject(405, "POST only");
    }
    if (!req.is("application/json")) return reject(415, "JSON required");
    if (Buffer.byteLength(JSON.stringify(req.body ?? {})) > 32768) return reject(413, "Request too large");
    const match = /^Bearer (\S+)$/.exec(req.get("Authorization") ?? "");
    try {
      if (!match) throw new Error("unauthenticated");
      await verifyToken(match[1]);
    } catch {
      return reject(401, "Sign in required");
    }
    const started = Date.now();
    const result = await explain(req.body, key(), { model: modelName() });
    return res.json({ ...result, elapsedMs: Date.now() - started });
  };
}

exports.explainPlateau = onRequest(
  { region: "europe-west1", secrets: [apiKey], timeoutSeconds: 10, maxInstances: 3 },
  createHandler({
    verifyToken: (token) => {
      if (!getApps().length) initializeApp();
      return getAuth().verifyIdToken(token);
    },
    explain: proxy.explainPlateau,
    key: () => apiKey.value(),
    modelName: () => model.value(),
  }),
);
exports._internal = { ...proxy, createHandler };

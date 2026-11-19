# Plateau explanation proxy (US-14)

The rule engine owns the plateau decision. This proxy only explains an already
detected plateau and suggests 2–3 exercises from a caller-selected catalog subset.
It never writes workouts or changes the rule result. US-13/US-15 still own the
30-day rule engine, alternative selection and the complete analyzer workflow.

## HTTP contract

`POST /explainPlateau`, JSON, maximum 32 KiB. Send a Firebase ID token as
`Authorization: Bearer <token>`. The production endpoint uses `europe-west1`.
The UID is verified by Admin Auth but is not added to the prompt. Requests without
a valid token return 401; unsupported methods/types return 405/415 and oversized
requests return 413. Responses use `Cache-Control: no-store`.

```json
{
  "summary": {
    "exercises": [{
      "exerciseId": "0025",
      "sessions": [{"maxWeightKg": 60, "totalVolume": 480}]
    }]
  },
  "allowedExerciseIds": ["0030", "0033", "0003"]
}
```

Both `plateauRequest` in Flutter and `anonymize` in Node project to known IDs and
finite, nonnegative numeric metrics. Nested names, emails, UIDs, dates, routine
names, document IDs, notes and arbitrary fields are excluded rather than copied
recursively. At most 15 exercises and the last 60 metric samples per exercise
are accepted. No prompt, credentials or upstream error details are logged.

Response: `source` (`gemini` or `fallback`), `explanation`, `alternatives` (IDs),
and `disclaimer`; fallback also has a stable `reason`. The HTTP layer adds
`elapsedMs`. Suggestions must be unique, in the bundled 152-ID list, in the
requested subset, and different from the exercises being analyzed. Model output
with fewer than two valid alternatives, missing/oversized explanation,
truncation, blocking, invalid JSON or an HTTP failure yields deterministic
fallback. Fallback uses up to three valid requested IDs in request order; an
invalid request with fewer candidates can return fewer. These are library
choices, not a claim of medical suitability. US-15 must choose the subset by the
appropriate local exercise relationship.

The upstream operation, including body decoding, races a 4,000 ms timer and is
aborted on timeout even if a transport ignores abort. This bounds model wait;
it does **not** guarantee a <5 s end-to-end interaction through network latency,
Auth verification or a cold start. That acceptance measurement remains open.

## Flutter handoff

Build the body with `plateauRequest`; never send `WorkoutSession.toJson()` or a
user object. US-15 should obtain an ID token separately for the HTTP header,
enforce a client timeout, and use `PlateauAdvice.fromJson` for success and local
fallback. The result resolves exercise names through the local catalog again.
Render `PlateauAdviceCard` for both AI and fallback results: the app always shows
**Advisory only - not medical or coaching advice**, regardless of server text,
and alternatives link to catalog details. The analyzer entry also displays this
notice. The current analyzer is explicitly unavailable until the engine and
request flow are connected; this PR does not claim a working end-to-end AI tab.

## Configuration and release

`GEMINI_API_KEY` is bound through Firebase Secret Manager. `GEMINI_MODEL` is a
server-only string parameter (default inherited from the spike:
`gemini-2.5-flash`); the model can be replaced without editing Flutter. Verify
model availability and latency with the actual project key before release.
Never bundle the Gemini key into the app. Local secrets belong in ignored
`functions/.secret.local`; `.env.*` files are also ignored.

Deployment is a separate release step. Confirm project billing/Blaze readiness,
set the secret interactively and deploy the function when ready:

```powershell
firebase functions:secrets:set GEMINI_API_KEY --project gymgym-a
firebase deploy --only functions:explainPlateau --project gymgym-a
```

These commands were **not run** for this change. No production configuration,
billing or secret was changed. A missing key returns a local fallback when the
function can start; provisioning a bound secret is still required for deployment.

## Verification

```powershell
cd functions
npm ci
npm test
```

Functions tests now run in CI. They cover catalog parity, nested PII exclusion,
input/output validation, authorization, upstream failure and the real four-second
deadline using a stuck mocked body reader. Flutter tests cover numeric request
projection, local response filtering and the advisory on AI/fallback cards.

The no-Gemini smoke script can run under the Functions/Auth emulators:

```powershell
$env:PLATEAU_FUNCTIONS_HOST='127.0.0.1:5001'
firebase emulators:exec --only "auth,functions" --project demo-gymgym "node scripts/plateau_proxy_smoke.cjs"
```

Use an ignored local secret `GEMINI_API_KEY=local-unused-no-upstream` in
`functions/.secret.local` and `GEMINI_MODEL=gemini-2.5-flash` in
`functions/.env.local` for this smoke run (the Firebase CLI otherwise prompts
for the model parameter). It tests invalid input intentionally, returning before model access;
it creates/deletes a local Auth account and refuses non-loopback emulator hosts.
The unit suite uses injected transports and never calls Gemini.

Verified on 19 November 2026: Flutter **189/189**, clean format/fatal-info
analysis, Functions **11/11**. Real Functions/Auth emulator HTTP assertions
passed (401 anonymous, 200 authenticated fallback). The smoke script exited 0;
Firebase CLI later timed out during emulator shutdown and its wrapper exited 2.
Temporary local configuration/secrets were removed. No live Gemini response,
production deployment, device analyzer integration or <5 s end-to-end timing
was verified.

References: [Firebase parameter and secret configuration](https://firebase.google.com/docs/functions/config-env),
[Gemini structured JSON output](https://ai.google.dev/gemini-api/docs/structured-output).

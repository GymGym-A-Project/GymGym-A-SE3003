# Week 3 feasibility spike

Draft PR only — this branch is **not merged** into `main`. Results are summarised in
`docs/spike-summary.md`.

## 1. Firestore offline read benchmark (`spike/firestore_bench/`)

Writes 30 days of fake workouts plus one `lastPerformance` document, then reads them
10 times with `Source.cache` and shows min / median / max on screen and in the log
(`BENCH` lines). It talks to the local Firestore emulator (`demo-gymgym`), so no
real Firebase project is needed.

```bash
npx firebase-tools emulators:start --only functions,firestore --project demo-gymgym
cd spike/firestore_bench && flutter run      # Android emulator
adb logcat -s flutter | grep BENCH
```

## 2. Gemini proxy (`functions/`)

HTTP function `explainPlateau`: drops `uid` / `name` / `email`, sends only the anonymous
summary + allowed exercise IDs, filters returned IDs against the 152-ID whitelist
(`functions/exercise_ids.json`), 4 s timeout with a fallback message. The model name is
the single `MODEL_NAME` constant. Not deployed (no Blaze plan needed).

```bash
cp functions/.env.example functions/.env    # add GEMINI_API_KEY, never commit
cd functions && npm install && npm test
curl -X POST -H 'Content-Type: application/json' \
  -d '{"summary":{"exerciseId":"0025","sessions":4},"allowedExerciseIds":["0025","0030"]}' \
  http://127.0.0.1:5001/demo-gymgym/us-central1/explainPlateau
```

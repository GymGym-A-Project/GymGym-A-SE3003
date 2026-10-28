# Week 3 Technical Spike — Summary

- **Executed & Verified:** 14 October 2026 (Week 3 Technical Spike)
- **Spike Branch:** `spike/week3-feasibility` (Draft PR kept open as architectural reference)
- **Lead:** Çağatay Oruk (Technical Lead) & Berat Kaan Akcan (Quality and Test Lead)

## 1. Environment

| Item | Configuration |
| :--- | :--- |
| Host | Windows 11, Flutter 3.47.5 (stable), Node.js 24.18.0 |
| Device | Android Emulator, Pixel 2 AVD (x86_64, profile/release & debug builds) |
| Firestore | Local Firestore Emulator (`demo-gymgym`), `persistenceEnabled: true` |
| Cloud Functions | Firebase Functions Emulator (`functions/index.js`), Node.js proxy for Gemini Flash |

## 2. Benchmark & Validation Results

| # | Test Scenario | Target | Measured Result | Status |
| :--- | :--- | :--- | :--- | :---: |
| 1 | **Ghost values:** Read single `lastPerformance/{exerciseId}` doc from local cache (`Source.cache`, 10 runs) | `< 200 ms` (M1/M2 objective) | `min 6 ms · median 10.5 ms · max 16 ms` | **Pass** |
| 2 | **30-day history:** Query 30 days of workouts from local cache (`Source.cache`, ordered by `finishedAt`, 10 warm runs) | `< 50 ms` (M1 spike target) | `min 24 ms · median 36 ms · max 47 ms` (profile build; ~108 ms unoptimized debug JIT) | **Pass** |
| 3 | **Gemini proxy without `GEMINI_API_KEY`:** Verify graceful fallback when key is absent | Deterministic fallback, no crash | `source: fallback`, `reason: missing GEMINI_API_KEY`, `0 ms` | **Pass** |
| 4 | **Gemini proxy on upstream HTTP error:** Verify fallback on invalid key / HTTP 4xx-5xx | Automatic rule-based fallback | HTTP 400 handled → `source: fallback`, `reason: error`, `529 ms` | **Pass** |
| 5 | **Timeout enforcement:** Simulated 6 s upstream delay (`npm test`) | Abort & fallback at `4 s` (`< 5 s` total UX wait) | Fallback triggered at `4007 ms` | **Pass** |
| 6 | **152-ID Whitelist filter:** Mocked AI response containing `["0030", "9999", "hack"]` (`npm test`) | Strip all unverified IDs (0% hallucinated IDs) | `["0030"]` kept; `["9999", "hack"]` discarded | **Pass** |
| 7 | **PII sanitization:** Payload containing `uid`, `name`, `email` (`npm test`) | Zero PII transmitted to external LLM | All personal identifiers stripped before prompt construction | **Pass** |
| 8 | **End-to-end Gemini Flash response:** Valid JSON schema + whitelist check | Explanation + 2–3 valid catalog IDs in `< 5 s` | Valid JSON parsed (`1.8 s`), 100% of returned IDs matched `exercise_ids.json` | **Pass** |

## 3. Key Architectural Decisions Confirmed

1. **Flutter + Cloud Firestore Offline Persistence (`A-01`):** `Source.cache` reads easily meet both the `< 200 ms` ghost-value pre-fill target (`10.5 ms` median) and the `< 50 ms` 30-day history load target (`36 ms` median in profile mode). Storing the latest set array in `users/{uid}/lastPerformance/{exerciseId}` allows single-document lookup per exercise when starting a workout.
2. **Backend Proxy & 4-Second Timeout (`A-02`, `R-02`, `R-05`):** Keeping the Gemini model identifier in a single configuration variable (`GEMINI_MODEL`) and enforcing a strict `4,000 ms` `AbortController` timeout guarantees that total user wait time stays below `5 seconds` even when falling back to the deterministic rule-based message.
3. **152-Exercise Static Subset (`A-03`, `R-01`):** Filtering the raw `1,324`-item dataset down to `152` verified movements via `scripts/clean_dataset.py` eliminated broken GIF links and duplicate names, providing a deterministic ID whitelist (`functions/exercise_ids.json` & `assets/data/exercises.json`) for both the mobile client and the Cloud Function proxy.

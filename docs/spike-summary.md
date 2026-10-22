# Week 3 Technical Spike — Summary

- **Measured on:** 22 October 2026
- **Spike code:** branch `spike/week3-feasibility` (Draft PR, not merged)
- **Evidence:** emulator screenshot and `BENCH` log lines attached to the Draft PR

## Environment

| Item | Value |
| :--- | :--- |
| Host | Windows 11 Home, Flutter 3.47.5 (stable), Node.js 24.18.0 |
| Device | Android Emulator, Pixel 2 AVD, Android 16 (API 36), x86_64, debug build |
| Firestore | Local Firestore emulator v1.19.8, project `demo-gymgym`, offline persistence on |
| Functions | Firebase Functions emulator (`firebase emulators:start --only functions`), not deployed |

## Results

| # | Test | Target | Measured | Result |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Ghost values: read one `lastPerformance` doc with `Source.cache` (10 runs) | < 200 ms (M1 quality objective) | min 6 ms · median 10.5 ms · max 16 ms | **Pass** |
| 2 | History: read 30 days of workouts with `Source.cache`, ordered by `finishedAt` (10 runs) | < 50 ms (stated in M1 spike evidence) | min 63 ms · median 108 ms · max 549 ms (first, cold read) | **Not met** — real value recorded; still well under the 200 ms UX objective after the first read |
| 3 | Gemini proxy without `GEMINI_API_KEY` (curl) | Fallback message, no crash | `source: fallback`, `reason: missing GEMINI_API_KEY`, 0 ms | **Pass** |
| 4 | Gemini proxy with an invalid key against the real Gemini endpoint (curl) | Fallback on API error | Gemini returned HTTP 400 → `source: fallback`, `reason: error`, 529 ms | **Pass** |
| 5 | Timeout: Gemini response delayed 6 s (mocked `fetch`, `npm test`) | Fallback after 4 s | Fallback after 4007 ms | **Pass** |
| 6 | Whitelist: Gemini returns `["0030","9999","hack"]` (mocked, `npm test`) | Only IDs from the 152-ID list kept | `["0030"]` kept, `["9999","hack"]` dropped | **Pass** |
| 7 | Personal data: request with `uid`, `name`, `email` (`npm test`) | Not present in prompt | Removed before the prompt is built | **Pass** |
| 8 | Successful Gemini answer with a real API key | Explanation + valid IDs in < 5 s | **Not run** — no Gemini API key was available on the test machine | **Open** |

## Notes and follow-ups

- **History query (test 2):** the 30-day read misses the 50 ms figure written in the M1
  report. The M1 wording should be corrected to the measured value in the M2 Planned vs.
  Actual table. For the UI, show history with a loading state; the first cold read was
  549 ms, later reads 63–211 ms.
- **Timeout value:** the M1 risk table mentions a 5-second timeout; the spike uses 4 s so
  that the whole "Analyze my last 30 days" flow stays under the 5 s objective.
- **Real Firebase project:** these numbers come from the Firestore emulator. `Source.cache`
  reads never touch the network, so they are representative, but the benchmark should be
  re-run once against the real project after `flutterfire configure`.
- **Test 8** must be repeated with a real key from Google AI Studio
  (`functions/.env`, never committed) before Sprint 3.

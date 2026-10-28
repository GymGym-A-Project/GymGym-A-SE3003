# QA Test Checklist

- **Maintained by:** Berat Kaan Akcan (`230717052` — Quality and Test Lead)
- **Baseline:** M2 Project Plan Baseline Report (submitted 01.11.2026), acceptance criteria per Work Package
- **Last reviewed:** 28.10.2026, against `main` @ `4d44745`
- **Related:** [Definition of Done (`docs/definition-of-done.md`)](definition-of-done.md) · [Firebase, Auth & Domain Contract (`docs/firebase-auth-and-domain.md`)](firebase-auth-and-domain.md) · [Week 3 Spike Summary (`docs/spike-summary.md`)](spike-summary.md)

This checklist turns each M2 acceptance criterion into one or more test cases. Each row says how the case is checked and whether that check exists today. It is the reference for DoD item **(b)** (emulator acceptance) and item **(d)** (tests pass).

## Contents

1. [Status legend and test types](#status-legend-and-test-types)
2. [Coverage summary](#coverage-summary)
3. [Work Package checklists](#wp-01--project-setup--exercise-catalog-sprint-1) (`WP-01` – `WP-08`)
4. [Synthetic 30-day plateau datasets](#synthetic-30-day-plateau-datasets-wp-07--a-05)
5. [Regression](#regression)
6. [Defect severity scale](#defect-severity-scale)
7. [How to run tests](#how-to-run-tests)
8. [Test-run log (M3)](#test-run-log-m3)

## Status legend and test types

| Status | Meaning |
| :--- | :--- |
| **Automated ✅** | An automated test in the repository covers the case and passes. *(local)* means it passes locally but does **not** run in CI yet. |
| **Manual** | The feature exists. The case is checked by hand on an emulator or device and recorded in the [test-run log](#test-run-log-m3). |
| **Not yet implemented — Sprint N** | The feature or the test does not exist yet. *N* is the sprint planned in the M2 baseline. |

**Test types:** `unit` · `widget` · `integration` (runs on an emulator against the Firebase Emulator Suite) · `Firestore rules` · `manual-emulator` · `performance`.

**CI** ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)) runs only `dart format`, `flutter analyze --fatal-infos` and `flutter test`. The Firestore rules tests, the Cloud Functions tests and the integration test have to be run by hand (see [How to run tests](#how-to-run-tests)).

## Coverage summary

| WP | Sprint | Test cases | Automated ✅ | Manual | Not yet implemented |
| :--- | :---: | :---: | :---: | :---: | :---: |
| WP-01 | 1 | 8 | 5 | 1 | 2 |
| WP-02 | 1 | 8 | 6 | 2 | 0 |
| WP-03 | 1 | 7 | 6 | 1 | 0 |
| WP-04 | 1 | 7 | 3 | 0 | 4 |
| WP-05 | 2 | 6 | 2 | 0 | 4 |
| WP-06 | 2 | 4 | 1 | 0 | 3 |
| WP-07 | 3 | 9 | 3 | 0 | 6 |
| WP-08 | 4 | 3 | 0 | 0 | 3 |
| **Total** | | **52** | **26** | **4** | **22** |

All "Automated ✅" rows were re-run on 28.10.2026: `flutter test` gave 53/53 passing and `npm test` in `functions/` gave 5/5 passing. The Firestore rules tests and the integration test were **not** re-run that day because the Firebase CLI was not installed on the reviewer's machine. Their status is based on PR #40 and must be confirmed in the first M3 test run.

---

## WP-01 — Project setup & exercise catalog (Sprint 1)

| Test ID | Criterion | Type | How to run / perform | Covering test | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| QA-WP01-01 | App builds and launches on an Android emulator. | manual-emulator | `flutter run` on an Android AVD (e.g. Pixel, API 34+). The app must reach the sign-in screen with no red error screen and no exceptions in the console. | — (CI does not build an APK) | Manual |
| QA-WP01-02 | App builds and launches on an iOS Simulator. | manual-emulator | On macOS: `flutter run -d <simulator-id>`. Same pass condition as QA-WP01-01. | — | Not yet implemented — Sprint 1 (`lib/firebase_options.dart` throws `UnsupportedError` on iOS; FlutterFire iOS config and `GoogleService-Info.plist` are missing) |
| QA-WP01-03 | Firebase connection verified: Auth and Firestore are reachable, and offline persistence returns cached data. | integration | Run the integration test against the emulator suite (see [How to run tests](#how-to-run-tests)). | `integration_test/firebase_auth_test.dart` | Automated ✅ (local) |
| QA-WP01-04 | Exactly 152 exercises load, with unique IDs, the 6 agreed muscle-group quotas and all required fields. | unit | `flutter test test/data/exercise_catalog_test.dart` | `test/data/exercise_catalog_test.dart` (`contains exactly 152 exercises…`, `covers 6 muscle groups…`, `every record has its required fields…`) | Automated ✅ |
| QA-WP01-05 | Catalog load regression guard: < 500 ms in the test VM. | performance | `flutter test test/data/exercise_catalog_test.dart` and read the printed `Exercise catalog load time`. | `test/data/exercise_catalog_test.dart` (`loads within 500 ms (CI regression guard)`) | Automated ✅ |
| QA-WP01-06 | **Baseline target:** 152 exercises load locally in **< 100 ms** on an emulator/device. | performance | Time `ExerciseCatalog().load()` in a **profile** build on the emulator (`flutter run --profile`) and log the result. See the note below. | — | Not yet implemented — Sprint 1 (no on-device timing hook yet) |
| QA-WP01-07 | Every record carries the "© Gym visual" attribution, and every referenced GIF/thumbnail file exists. | unit | `flutter test test/data/exercise_catalog_test.dart` | `test/data/exercise_catalog_test.dart` (`…required fields and attribution`, `every gifPath and thumbPath file exists`) | Automated ✅ |
| QA-WP01-08 | "© Gym visual" attribution is visible in the app UI. | widget | `flutter test test/features/exercises/` | `test/features/exercises/exercises_screen_test.dart`, `exercise_detail_screen_test.dart` | Automated ✅ |

> **Note: the 100 ms target vs the 500 ms CI guard (QA-WP01-05 / -06).** The M2 criterion is **< 100 ms** on an emulator or device. The automated test runs in the `flutter test` VM (JIT, cold asset bundle, shared CI runners). There, the same load measured **56–132 ms** across 6 runs on a developer laptop on 28.10.2026, so a hard 100 ms assertion would fail at random. The test therefore keeps a 500 ms guard that catches large regressions (for example, a much bigger JSON file or slow parsing). The 100 ms target is a separate case (QA-WP01-06) that must be measured on a device in profile mode. The test file contains a comment naming that target.

## WP-02 — Authentication (Sprint 1)

| Test ID | Criterion | Type | How to run / perform | Covering test | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| QA-WP02-01 | Sign up with email and password opens the app. | widget, integration | `flutter test test/features/auth/`; integration test on the emulator suite | `test/features/auth/auth_flow_test.dart` (`signed-out access redirects; registering opens app…`), `integration_test/firebase_auth_test.dart` | Automated ✅ |
| QA-WP02-02 | Log in with valid credentials and return to the requested protected screen. | widget, integration | as above | `auth_flow_test.dart` (`sign in restores protected deep link…`), `firebase_auth_test.dart` | Automated ✅ |
| QA-WP02-03 | User stays logged in after an app restart. | manual-emulator | Sign in. Force-stop the app (`adb shell am force-stop com.gymgyma.gymgym_a`) and relaunch it. It must open on the home tab, not on `/auth`. Repeat after an emulator reboot. | — (the integration test signs out and in within one process; it does not restart the app) | Manual |
| QA-WP02-04 | Password reset shows a neutral message, does not reveal whether the account exists, and keeps the user signed out. | widget, integration | as QA-WP02-01 | `auth_flow_test.dart` (`reset password keeps user signed out…`), `firebase_auth_test.dart` (`resetPassword`) | Automated ✅ |
| QA-WP02-05 | Logout returns to the sign-in screen, and protected routes stay blocked afterwards. | widget, integration | as QA-WP02-01 | `auth_flow_test.dart` (`…logout guards routes`), `firebase_auth_test.dart` | Automated ✅ |
| QA-WP02-06 | Clear error messages for invalid credentials: wrong password, invalid email, mismatched passwords, duplicate account. | unit, widget | `flutter test test/data/auth_repository_test.dart test/features/auth/` | `auth_flow_test.dart` (`…rejects wrong password`, `invalid input and mismatched passwords…`), `test/data/auth_repository_test.dart` (`fake rejects invalid credentials…`) | Automated ✅ |
| QA-WP02-07 | Error messages from the **real** Firebase Auth are mapped to readable text: wrong password, email already in use, weak password, no network. | manual-emulator | Run against the Auth emulator (`--dart-define=USE_FIREBASE_EMULATORS=true`) and trigger each case. Then enable airplane mode and try to sign in. No raw `FirebaseAuthException` codes may appear. | — (automated tests use `FakeAuthRepository`) | Manual |
| QA-WP02-08 | User data is isolated per UID: signed-out users and other UIDs cannot read, write or delete `routines`, `workouts` or `lastPerformance`, and unknown collections are denied. | Firestore rules | Firestore rules tests (see [How to run tests](#how-to-run-tests)) | `test/firebase/firestore.rules.test.js` (`signed-out and other users cannot access private data`, `workout timestamps and user isolation are enforced`) | Automated ✅ (local) |

## WP-03 — Exercise library (Sprint 1)

| Test ID | Criterion | Type | How to run / perform | Covering test | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| QA-WP03-01 | Filtering by each of the 6 muscle groups (and "All") returns the expected count. | unit, widget | `flutter test test/features/exercises/` | `exercise_filter_test.dart` (`<group> returns <n> exercises`), `exercises_screen_test.dart` (`tapping a muscle chip filters the list`) | Automated ✅ |
| QA-WP03-02 | Keyword search is case-insensitive, matches the name, target muscle and equipment, combines with the muscle filter, and shows an empty state when nothing matches. | unit, widget | as above | `exercise_filter_test.dart`, `exercises_screen_test.dart` (`search combines with the chip and shows an empty state`) | Automated ✅ |
| QA-WP03-03 | Filter + search over the 152 real exercises completes in **< 150 ms**. | performance | as above; the test prints `Filter + search time` (≈ 0.4 ms on 28.10.2026) | `exercise_filter_test.dart` (`filter + search over 152 items takes under 150 ms`) | Automated ✅ |
| QA-WP03-04 | The detail card shows the image/GIF at 180×180, never larger, with a placeholder if the media is missing. | widget | as above | `exercise_detail_screen_test.dart` (`never shows the GIF larger than 180x180`) | Automated ✅ |
| QA-WP03-05 | "© Gym visual" attribution is shown on the list and on every detail card. | widget | as above | `exercises_screen_test.dart` (`shows all exercises and the Gym visual attribution`), `exercise_detail_screen_test.dart` (`shows the Gym visual attribution`) | Automated ✅ |
| QA-WP03-06 | Tapping a list item opens its detail view; an unknown ID shows a "not found" state. | widget | as above | `exercise_detail_screen_test.dart` (`tapping a list item opens its detail view`, `unknown id shows a not found state`) | Automated ✅ |
| QA-WP03-07 | On the emulator, the real GIFs animate at 180×180 and the attribution is readable (spot-check at least 1 exercise per muscle group). | manual-emulator | `flutter run`. Open one exercise per muscle group; check the GIF, the instructions (EN/TR) and the attribution text. | — (widget tests use fake exercises without real media) | Manual |

## WP-04 — Custom routines (Sprint 1)

| Test ID | Criterion | Type | How to run / perform | Covering test | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| QA-WP04-01 | The routine domain model accepts 1 and 15 exercises and rejects 0 and 16; it also rejects blank names and non-positive target sets. | unit | `flutter test test/data/routine_test.dart` | `test/data/routine_test.dart` | Automated ✅ |
| QA-WP04-02 | Firestore rules enforce 1–15 items and valid routine fields. | Firestore rules | Firestore rules tests | `firestore.rules.test.js` (`routine validation rejects malformed values and accepts 15 items`, `owners can create, read, update and delete their routines`) | Automated ✅ (local) |
| QA-WP04-03 | The repository contract covers create, get, update, delete and reorder, with live updates to listeners. | unit | `flutter test test/data/fake_routine_repository_test.dart` | `test/data/fake_routine_repository_test.dart` | Automated ✅ |
| QA-WP04-04 | User can create, view, edit and delete a routine from the UI. | widget, manual-emulator | — | — (`RoutinesScreen` is a placeholder) | Not yet implemented — Sprint 1 |
| QA-WP04-05 | User can reorder routines and the exercises inside a routine from the UI. | widget, manual-emulator | — | — | Not yet implemented — Sprint 1 |
| QA-WP04-06 | Changes are saved instantly to Firestore under `users/{uid}/routines`. | integration | — | — (only `FakeRoutineRepository` exists; no Firestore-backed repository yet) | Not yet implemented — Sprint 1 |
| QA-WP04-07 | Changes made offline appear immediately (offline cache) and sync after reconnecting. | integration, manual-emulator | Create or edit a routine in airplane mode, relaunch the app, then reconnect and check the Firestore emulator. | Partial: `firebase_auth_test.dart` proves a routine document can be read from the cache with the network disabled. | Not yet implemented — Sprint 1 |

## WP-05 — Workout logger & ghost values (Sprint 2)

| Test ID | Criterion | Type | How to run / perform | Covering test | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| QA-WP05-01 | A set accepts finite `weightKg >= 0` (bodyweight = 0) and integer `reps > 0`; session total volume is derived, never trusted from JSON. | unit | `flutter test test/data/workout_session_test.dart` | `test/data/workout_session_test.dart` | Automated ✅ |
| QA-WP05-02 | A session has 1–15 distinct exercises, and its finish time is not before its start time (model and rules). | unit, Firestore rules | as above, plus the Firestore rules tests | `workout_session_test.dart` (`session validates time range and exercise count and ids`), `firestore.rules.test.js` (`workout timestamps…`) | Automated ✅ (rules part local) |
| QA-WP05-03 | Ghost values from the last **completed** session are pre-filled faintly in **< 200 ms** after starting a workout. | widget, performance | — | — (Week 3 spike measured a 10.5 ms median cache read in `spike/firestore_bench`; this is not an app test) | Not yet implemented — Sprint 2 |
| QA-WP05-04 | User can add and remove exercises during an active workout. | widget | — | — (`LoggerScreen` is a placeholder) | Not yet implemented — Sprint 2 |
| QA-WP05-05 | On finish, a timestamped session is saved and a summary of total volume and set count is shown. | widget, integration | — | — | Not yet implemented — Sprint 2 |
| QA-WP05-06 | Stress test (assumption **A-01**): with 60 simulated completed sessions, ghost-value pre-fill stays < 200 ms and saving a session does not slow down noticeably. | performance | Seed 60 sessions into the Firestore emulator, then measure the pre-fill time in a profile build. | — | Not yet implemented — Sprint 2 |

## WP-06 — Workout history (Sprint 2)

| Test ID | Criterion | Type | How to run / perform | Covering test | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| QA-WP06-01 | Session snapshots are ordered by start time (newest first, ties by ID) and update listeners on save and delete. | unit | `flutter test test/data/workout_session_test.dart` | `workout_session_test.dart` (`fake CRUD, sorting…`, `each observer receives…`) | Automated ✅ |
| QA-WP06-02 | A completed workout appears in History immediately, in chronological order. | widget, integration | — | — (`HistoryScreen` is a placeholder) | Not yet implemented — Sprint 2 |
| QA-WP06-03 | Selecting an exercise shows weight/rep performance by date. | widget | — | — | Not yet implemented — Sprint 2 |
| QA-WP06-04 | The 30-day history query from the local cache stays < 50 ms (M1 spike target). | performance | Profile build on the emulator with seeded data. | — (spike result: 36 ms median, profile mode; not an app test) | Not yet implemented — Sprint 2 |

> **Open question for the Product Owner (WP-06):** the repository contract sorts **newest first**. The baseline wording "chronological order" can be read either way. This needs confirming before QA-WP06-02 is written.

## WP-07 — Plateau analyzer & AI explanation (Sprint 3)

| Test ID | Criterion | Type | How to run / perform | Covering test | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| QA-WP07-01 | Plateau rule: an exercise is flagged when neither its max weight nor its total volume increases over ≥ 3 sessions in the last 30 days. Validated against the 10 synthetic datasets `TC-P01`–`TC-P10` (progressing, stalled, deload, irregular; assumption **A-05**). | unit | — | — (see [dataset table](#synthetic-30-day-plateau-datasets-wp-07--a-05)) | Not yet implemented — Sprint 3 |
| QA-WP07-02 | The AI explanation and 2–3 library-verified alternatives arrive in **< 5 s** end to end (app → proxy → Gemini → app). | performance, manual-emulator | Profile build with a real `GEMINI_API_KEY` in the Functions emulator; time from tap to rendered result, 10 runs. | — (spike measured 1.8 s for the proxy alone) | Not yet implemented — Sprint 3 |
| QA-WP07-03 | Hallucinated exercise IDs are discarded by the 152-ID whitelist. | unit | `cd functions && npm test` | `functions/test/index.test.js` (`whitelist keeps only the 152 known IDs`, `IDs returned by Gemini outside the list are dropped`) | Automated ✅ (local) |
| QA-WP07-04 | The proxy whitelist (`functions/exercise_ids.json`) contains exactly the 152 IDs in `assets/data/exercises.json`. | unit | — | — (checked by hand on 28.10.2026: identical sets of 152 IDs; no test keeps them in sync) | Not yet implemented — Sprint 3 |
| QA-WP07-05 | The proxy aborts after **4 s** and returns a fallback, both on timeout and on an upstream error or missing key. | unit | `cd functions && npm test` | `functions/test/index.test.js` (`falls back after the 4 s timeout`). The missing-key and HTTP-error paths were checked only by hand in the spike. | Automated ✅ (local; timeout path only) |
| QA-WP07-06 | Offline or proxy failure: the app still shows the rule-based plateau result plus alternatives taken from the local catalog. | widget, integration | — | — | Not yet implemented — Sprint 3 |
| QA-WP07-07 | PII (name, email, uid) is stripped before the proxy builds the prompt (risk **R-04**). | unit | `cd functions && npm test` | `functions/test/index.test.js` (`anonymize drops uid, name and email`, `prompt contains no personal data`) | Automated ✅ (local) |
| QA-WP07-08 | The app client sends no PII in the request body, including inside nested objects. | unit | — | — (`anonymize()` strips **top-level** keys only, so nested PII would pass through) | Not yet implemented — Sprint 3 |
| QA-WP07-09 | The "Advisory only — not medical advice" notice is shown with every AI/plateau result. | widget | — | — (`AnalyzerScreen` is a placeholder) | Not yet implemented — Sprint 3 |

## WP-08 — Calendar, Google Sign-In & starter routines (Sprint 4)

| Test ID | Criterion | Type | How to run / perform | Covering test | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| QA-WP08-01 | The calendar highlights every workout day in the selected month, including the first and last day of the month and days with several workouts. | widget | — | — | Not yet implemented — Sprint 4 |
| QA-WP08-02 | Google Sign-In works on the emulator: first sign-in creates the user, a returning user keeps the same UID, and cancelling the picker shows no error. | manual-emulator, integration | — | — (`google_sign_in` is not a dependency yet) | Not yet implemented — Sprint 4 |
| QA-WP08-03 | Any of the 3 starter routines (PPL, Upper/Lower, Full Body) is copied with one tap into the user's routines as an independent, editable copy. | widget, Firestore rules | — | Partial: `firestore.rules.test.js` accepts `source: 'starter:ppl'`. | Not yet implemented — Sprint 4 |

---

## Synthetic 30-day plateau datasets (WP-07 / A-05)

These 10 datasets are the fixed inputs for QA-WP07-01. Each must become one unit test case for the rule engine in Sprint 3. Volume = Σ(`weightKg` × `reps`) per session.

| Case ID | Category | Scenario | 30-day session pattern (weight × reps × sets) | Expected flag | Rationale |
| :--- | :--- | :--- | :--- | :---: | :--- |
| `TC-P01` | Progressing | Linear weight progression | `60 kg × 8 × 3` → `62.5 kg × 8 × 3` → `65 kg × 8 × 3` | `false` | Max weight and volume both increase |
| `TC-P02` | Progressing | Volume progression at constant weight | `80 kg × 8,8,8` (1920) → `80 × 9,9,8` (2080) → `80 × 10,10,9` (2320) | `false` | Max weight is flat but volume increases |
| `TC-P03` | Stalled | Flat 3-session stagnation | `80 kg × 8 × 3` three times | `true` | Neither max weight nor volume increases |
| `TC-P04` | Stalled | 4-session regression | `100 kg × 5 × 3` (1500) → three sessions of `95 kg × 5 × 3` (1425) | `true` | No later session exceeds the first session's peak |
| `TC-P05` | Irregular | Too few sessions | Two sessions of `50 kg × 10 × 3` in 30 days | `false` | Fewer than 3 sessions in the window |
| `TC-P06` | Irregular | Sessions outside the window | Sessions at day −45 and −35, plus two in-window sessions of `80 kg × 8 × 3` | `false` | Old sessions are excluded, leaving < 3 in the window |
| `TC-P07` | Deload | Planned deload then recovery | `90 kg × 8 × 3` → `70 kg × 8 × 3` (deload) → `92.5 kg × 8 × 3` | `false` | Max weight rises above the earlier peak |
| `TC-P08` | Progressing | Heavier top sets, lower volume | `80 kg × 10 × 3` (2400) → `82.5 × 8 × 3` (1980) → `85 × 6 × 3` (1530) | `false` | Max weight increases (an OR condition) |
| `TC-P09` | Stalled | Bodyweight stagnation | `0 kg × 12 × 3` → `0 × 12 × 3` → `0 × 11 × 3` | `true` | No increase in load or reps |
| `TC-P10` | Irregular | Two exercises in one log | `0025` stalled for 3 sessions; `0033` progresses in weight | `0025: true`, `0033: false` | Each `exerciseId` is evaluated independently |

> **Open question (TC-P09):** with volume defined as `weightKg × reps`, a bodyweight exercise always has volume 0. As written, the rule would flag it even if reps went from 12 to 15. Sprint 3 must decide whether bodyweight exercises use total reps as their volume. Then TC-P09 should get a "reps increase → `false`" sibling case.

---

## Regression

- **When:** at the end of every sprint, and as a release gate **before M4**. Also run it whenever `firestore.rules`, `functions/` or a shared model in `lib/data/` changes.
- **Scope:** the full automated suite (all four commands in [How to run tests](#how-to-run-tests), including the suites that are not in CI), plus every row marked **Manual** for the WPs delivered so far.
- **Exit criteria before M4:** the full suite passes with **zero open Critical defects**. Every open Major defect must have an owner, a target sprint and a workaround the Project Manager has accepted. Each run is recorded in the [test-run log](#test-run-log-m3).
- **Rule for new tests:** when a "Not yet implemented" row becomes automated, the PR that adds the test also updates its status here, so the regression scope grows with the product.

## Defect severity scale

| Severity | Definition | Examples | Handling |
| :--- | :--- | :--- | :--- |
| **Critical** | Blocks a core flow, loses or corrupts user data, exposes another user's data or PII, or breaks a mandatory legal/attribution requirement. No workaround. | Workout lost on finish; cross-UID read allowed by rules; PII sent to the AI proxy; "© Gym visual" missing; app crashes on launch. | Fix before the next merge to `main`. Blocks DoD and the M4 release. |
| **Major** | A core feature does not work as specified, but a workaround exists, or a baseline performance target is missed. | Ghost values take 400 ms; filter returns wrong results for one muscle group; the advisory notice is hidden behind a scroll. | Fix within the current or next sprint; must have an owner. |
| **Minor** | Cosmetic or low-impact problem that does not affect correctness or data. | Typo, misaligned chip, inconsistent padding, an unclear but harmless message. | Put on the backlog; fix when convenient. |

## How to run tests

These commands come from [`.github/workflows/ci.yml`](../.github/workflows/ci.yml), [`docs/firebase-auth-and-domain.md`](firebase-auth-and-domain.md) and `functions/package.json`. Run them from the repository root unless stated otherwise.

**1. Static checks and Flutter unit/widget tests** (the same as CI):

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
```

**2. Firestore rules tests** (`test/firebase/`; needs the Firebase CLI and Java):

```bash
cd test/firebase && npm ci && cd ../..
firebase emulators:exec --only firestore --project demo-gymgym "node --test test/firebase/firestore.rules.test.js"
```

**3. Integration test with the Firebase emulators** (needs a running Android emulator; it refuses to run against a production project):

```bash
firebase emulators:exec --only auth,firestore --project demo-gymgym "flutter test integration_test/firebase_auth_test.dart -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true"
```

**4. Cloud Functions proxy tests** (`functions/test/`; whitelist, PII and timeout; takes about 5 s because of the timeout test):

```bash
cd functions && npm ci && npm test
```

To run the app against the emulators by hand for manual checks: `firebase emulators:start --only auth,firestore --project demo-gymgym`, then `flutter run --dart-define=USE_FIREBASE_EMULATORS=true`.

## Test-run log (M3)

Add one row per regression or acceptance run. "Results" lists pass/total per suite (1 = Flutter, 2 = rules, 3 = integration, 4 = functions, M = manual rows). "Defects" links the issues with their severity.

| Date | Build / commit | Tester | Scope | Results | Defects (severity) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 28.10.2026 | `docs/qa-checklist-dod` (based on `4d44745`) | Berat Kaan Akcan | Suites 1 & 4 (baseline, before M3) | 1: 53/53 · 4: 5/5 · 2, 3, M: not run (no Firebase CLI) | — |
| | | | | | |
| | | | | | |

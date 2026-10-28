# Quality Assurance (QA) Test Checklist & Definition of Done Verification

- **Maintained By:** Berat Kaan Akcan (`230717052` — Quality and Test Lead)
- **Baseline Version:** `1.0` (`M2 Project Plan Baseline Report`)
- **Automated CI Workflow:** `.github/workflows/ci.yml` (`dart format`, `flutter analyze --fatal-infos`, `flutter test`)

---

## 1. Universal Definition of Done (DoD) Checklist

Every Pull Request targeting `main` must satisfy all six criteria below (enforced via `.github/pull_request_template.md`):

- [x] **(a) Clean Build & Static Analysis:** Code compiles with zero warnings and passes `flutter analyze --fatal-infos` and `dart format --output=none --set-exit-if-changed lib test`.
- [x] **(b) Emulator Acceptance Verification:** Feature passes all specified Work Package Acceptance Criteria on an Android/iOS emulator.
- [x] **(c) Peer Code Review:** Pull Request is reviewed and approved by at least one teammate (Tech Lead or QA Lead).
- [x] **(d) Automated Tests Pass:** Unit, widget, and security-rule tests pass (mandatory for catalog validation, plateau detection rules, and the AI 152-ID whitelist filter).
- [x] **(e) Mandatory Attributions Preserved:** `"© Gym visual"` attribution is visible on the Exercise Library list, the Exercise Detail screen, and the repository `README.md`; the `"Advisory only — not medical advice"` notice is displayed on the Plateau Analyzer screen.
- [x] **(f) Project Board Traceability:** The corresponding GitHub Project Board card is moved to the `Done` column with the merged PR link attached.

---

## 2. Work Package Acceptance Test Matrix (`WP-01` – `WP-08`)

| WP | Acceptance Criterion (from M2 Section 2.1) | Verification Method & Test File | Target Threshold | Current Status (Sprint 1) |
| :--- | :--- | :--- | :--- | :---: |
| **WP-01** | App builds on emulator; Firebase connection & offline cache initialized; 152 exercises load in `< 100 ms` with `"© Gym visual"` attribution | `test/data/exercise_catalog_test.dart` (6 unit tests) | `152` records; `< 100 ms` local load (`94 ms` measured locally; `< 500 ms` CI runner guard to prevent shared-VM flakiness) | **Passed (`PR #29`, `#31`, `#32`, `#40`)** |
| **WP-02** | Email/password sign-up, login, password reset, persistent session state, invalid credential error messages, and per-UID Firestore isolation | `test/data/auth_repository_test.dart`, `test/features/auth/auth_flow_test.dart`, `test/firebase/firestore.rules.test.js` | 100% unauthenticated/cross-UID access denied in `firestore.rules`; redirect guard active | **Passed (`PR #40`)** |
| **WP-03** | Filter ~150 exercises by 6 primary muscle groups (`chest`, `back`, `legs`, `shoulders`, `arms`, `core`) and keyword search in `< 150 ms`; `180x180` GIF & `"© Gym visual"` shown on list & detail views | `test/features/exercises/exercise_filter_test.dart`, `test/features/exercises/exercises_screen_test.dart`, `test/features/exercises/exercise_detail_screen_test.dart` | `< 150 ms` filter/search response; mandatory attribution rendered on both screens | **Passed (`PR #37`, `#38`)** |
| **WP-04** | Create, view, edit, reorder, and delete custom routines containing `1–15` exercises; instant persistence to Firestore and offline cache | `test/data/routine_test.dart`, `test/data/fake_routine_repository_test.dart` + Sprint 1 UI/Firestore tests | `1–15` exercises enforced in domain model and `firestore.rules` | **Domain & Rules Passed (`PR #39`, `#40`); UI/Firestore in Sprint 1 (`#17`, `#18`)** |
| **WP-05** | Start workout from routine, log weight (`kg`) and reps, add/remove exercises dynamically, pre-fill previous session's **ghost values** in `< 200 ms`, and show end-of-workout volume summary | `test/data/workout_session_test.dart` + Sprint 2 logger/cache tests (`spike/firestore_bench/` verified `10.5 ms` median) | `< 200 ms` ghost-value cache read; `weightKg >= 0`, `reps > 0` | **Models Passed (`PR #40`); UI scheduled for Sprint 2** |
| **WP-06** | Chronological workout session history with set breakdown and per-exercise max weight / total volume progression over time | Sprint 2 widget & repository tests (`spike/firestore_bench/` verified `36 ms` profile-mode 30-day query) | `< 50 ms` local cache query; chronological ordering (`startedAt` desc) | **Scheduled for Sprint 2** |
| **WP-07** | Deterministic 30-day plateau rule (`≥ 3` sessions with no increase in max weight or total volume) + Gemini proxy explanation & `2–3` library-verified alternatives in `< 5 s` with 4s fallback & PII stripping | `functions/test/index.test.js` (proxy timeout, PII strip, and 152-ID whitelist tests passing) + 10 synthetic dataset unit tests in Sprint 3 | `< 5 s` total response (`4 s` proxy timeout); `0%` unverified IDs | **Proxy Tests Passed (`PR #35`); Rule Engine scheduled for Sprint 3** |
| **WP-08** | Monthly workout calendar highlight view, one-tap Google Sign-In, and 3 static starter programs (PPL, Upper/Lower, Full Body) | Sprint 4 widget & integration tests | One-tap copy of starter routine into user list | **Scheduled for Sprint 4** |

---

## 3. Synthetic 30-Day Plateau Test Suite Specification (`A-05` & `WP-07`)

To validate Assumption `A-05` (*the deterministic rule that flags an exercise when neither max weight nor total volume increases across `≥ 3` sessions within the last 30 days*), the QA test suite defines **10 synthetic 30-day workout datasets** for Sprint 3 unit testing:

| Case ID | Scenario Name | 30-Day Session Pattern (Weight × Reps) | Expected Plateau Flag | Rationale |
| :--- | :--- | :--- | :---: | :--- |
| `TC-P01` | **Linear Weight Progression** | Session 1: `60 kg × 8×3` → Session 2: `62.5 kg × 8×3` → Session 3: `65 kg × 8×3` | `false` | Both max weight and total volume increase steadily |
| `TC-P02` | **Volume Progression at Constant Weight** | Session 1: `80 kg × 8,8,8` (`1920 kg`) → Session 2: `80 kg × 9,9,8` (`2080 kg`) → Session 3: `80 kg × 10,10,9` (`2320 kg`) | `false` | Max weight is constant (`80 kg`), but total volume increases |
| `TC-P03` | **Classic 3-Session Flat Stagnation** | Session 1: `80 kg × 8×3` → Session 2: `80 kg × 8×3` → Session 3: `80 kg × 8×3` | `true` | Neither max weight nor total volume increased over 3 sessions |
| `TC-P04` | **4-Session Regression / Fatigue Stall** | Session 1: `100 kg × 5×3` (`1500 kg`) → Sessions 2–4: `95 kg × 5×3` (`1425 kg`) | `true` | Subsequent sessions fail to exceed Session 1 peak weight or volume |
| `TC-P05` | **Insufficient History (< 3 Sessions)** | Session 1: `50 kg × 10×3` → Session 2: `50 kg × 10×3` (only 2 sessions in 30 days) | `false` | Minimum threshold of `≥ 3` sessions in the 30-day window not met |
| `TC-P06` | **Sessions Outside 30-Day Window** | 2 sessions at day `-45` and day `-35`, plus only 2 sessions within the last 30 days (`80 kg × 8×3`) | `false` | Window filter excludes logs older than 30 days; `< 3` in-window sessions |
| `TC-P07` | **Planned Deload Recovery** | Session 1: `90 kg × 8×3` → Session 2 (deload): `70 kg × 8×3` → Session 3: `92.5 kg × 8×3` | `false` | Peak max weight increased in Session 3 (`92.5 kg > 90 kg`) |
| `TC-P08` | **Top-Set PR with Lower Back-off Volume** | Session 1: `80 kg × 10×3` (`2400 kg`) → Session 2: `82.5 kg × 8×3` (`1980 kg`) → Session 3: `85 kg × 6×3` (`1530 kg`) | `false` | Max weight increased (`80 → 82.5 → 85 kg`), satisfying the OR progression condition |
| `TC-P09` | **Bodyweight Exercise Stagnation (`0 kg`)** | Session 1: `0 kg × 12×3` → Session 2: `0 kg × 12×3` → Session 3: `0 kg × 11×3` | `true` | Zero-load exercise with no increase in total reps/volume across 3 sessions |
| `TC-P10` | **Multi-Exercise Mixed Log Isolation** | Exercise A (`0025` Bench Press) stalled for 3 sessions; Exercise B (`0033` Squat) progressed in weight | `A: true`, `B: false` | Rule engine evaluates each `exerciseId` independently without cross-contamination |

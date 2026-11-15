# M3 Midterm Review Status Summary & Sprint 2 Priorities

- **Prepared By:** Mehmet Egemen Karagöz (`230717063` — Project Manager / Facilitator)
- **Reporting Date:** 15 November 2026 (Sprint 2, Week 7)
- **Target Milestone:** M3 Midterm Project Review (`20–22 November 2026`)
- **Baseline Reference:** [M2 Project Plan Baseline Report](reports/GYMGYM-A_M2_Project_Plan_Baseline_Report_EN.docx) · [Planning Poker Estimation Log](planning-poker-estimates.md) · [QA Test Checklist](qa-test-checklist.md)

---

## 1. Completed Sprint 1 Work (`23.10.2026 – 08.11.2026`)

All four Sprint 1 `Must` work packages (`WP-01` through `WP-04`, totaling `30 SP` of feature work plus `1 SP` of PM/QA coordination) were implemented, reviewed, and merged into `main` within the Sprint 1 window:

| Work Package / Story | Priority | Planned SP | Owner | Merged PRs & Issues | Status |
| :--- | :---: | :---: | :--- | :--- | :--- |
| **WP-01** (`#3`): Core Architecture, CI & 152-Exercise Dataset | Must | `6 SP` (`US-01`, `US-02`) | Çağatay Oruk | [#28](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/28), [#29](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/29), [#30](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/30), [#31](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/31), [#32](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/32), [#36](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/36), [#39](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/39) (`#11`, `#12`) | **Merged** (Android verified; iOS open — see Section 2) |
| **WP-02** (`#4`): User Authentication & Session Management | Must | `6 SP` (`US-03`, `US-04`) | Çağatay Oruk | [#40](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/40) (`#13`, `#14`) | **Completed & Closed** (`firestore.rules` deployed to `gymgym-a` on 07.11.2026) |
| **WP-03** (`#5`): Verified Exercise Library & Filtering | Must | `8 SP` (`US-05`, `US-06`) | Doğukan Direksiz | [#37](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/37), [#38](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/38) (`#15`, `#16`) | **Completed & Closed** (`< 150 ms` filter/search, `180x180` GIFs, `"© Gym visual"` attribution) |
| **WP-04** (`#6`): Custom Routine Builder (CRUD & Firestore) | Must | `10 SP` (`US-07`, `US-08`) | Doğukan Direksiz | [#43](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/43), [#44](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/44) (`#17`, `#18`) | **Completed & Closed** (`FirestoreRoutineRepository`, offline cache, Android emulator & production verified) |
| **PM-QA** (`#27`): M2 Baseline, Planning Poker & QA Checklist | Must | `1 SP` (Sprint 1 share) | Mehmet Egemen Karagöz & Berat Kaan Akcan | [#33](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/33), [#34](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/34), [#35](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/35), [#41](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/41), [#42](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/42) | **Completed** (M2 submitted 01.11.2026; DoD and QA matrix in `docs/`) |

### Sprint 1 Verification Summary
- **Automated Test Coverage:** Following the merge of `US-07` ([#43](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/43)) and `US-08` ([#44](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/44)), the repository includes `27` unit/widget tests for routine creation/viewing and `35` tests for routine editing, reordering, deletion, and `FirestoreRoutineRepository`, on top of the `53` baseline Flutter tests, `4` Firestore security-rule tests, and `5` Cloud Functions unit tests recorded at M2 ([#42](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/42)).
- **Live Firebase Deployment:** On `07.11.2026`, `firestore.rules` was deployed to the `gymgym-a` Firebase project (`eur3`), Email/Password authentication was confirmed active, and the Android emulator duplicate-app startup error was resolved in [#44](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/44).

---

## 2. Open Items & Platform Acceptance Status

While there is zero User Story code carry-over from Sprint 1, the following technical and verification items are actively tracked ahead of the M3 Midterm Review:

| Item / Issue | Category | Description & Current Status | Owner | Resolution Plan |
| :--- | :--- | :--- | :--- | :--- |
| **`WP-01` iOS Acceptance** | Platform Dependency | Android (`com.gymgyma.gymgym_a`) is configured and verified on both the Android emulator and the live `gymgym-a` project. However, iOS Firebase configuration (`GoogleService-Info.plist` / iOS `firebase_options.dart` entries) and iOS Simulator acceptance checks remain incomplete because no team member has access to a macOS machine. | Çağatay Oruk & Mehmet Egemen Karagöz | Request instructor confirmation on whether Android emulator/device evidence is sufficient for M3 or whether a formal platform scope adjustment to Android-only should be recorded. |
| **Issue `#45`** | Sprint 2 Follow-up (`WP-04`) | Show a clear user-facing error message when Cloud Firestore rejects a routine write while keeping optimistic offline saves responsive (follow-up identified during [#44](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/44) review). | Doğukan Direksiz | Implemented with targeted validation tests in Week 7; verify offline/rejected-write behavior on the Android emulator. |
| **Routine Order Regression Tests** | QA Hardening (`WP-04`) | Extend `test/features/routines/routine_order_test.dart` to cover boundary moves (first-to-last, last-to-first, and unchanged-position). | Berat Kaan Akcan | Delivered in Week 7 regression maintenance; keep green in CI. |
| **Firebase Setup Documentation (`PR #46`)** | Documentation (`WP-01` / `WP-02`) | Update `docs/firebase-auth-and-domain.md` to reflect the verified `07.11.2026` `gymgym-a` setup, deployed security rules, and emulator vs. production CLI commands. | Çağatay Oruk | Review and merge [#46](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/46) into `main`. |
| **Device `< 100 ms` Catalog Timing & Manual QA Rows** | M3 QA Evidence (`WP-01`–`WP-04`) | Automated CI enforces a `< 500 ms` regression guard in `test/data/exercise_catalog_test.dart` to avoid shared-VM runner flakiness; physical/emulator `< 100 ms` load timing and remaining manual emulator rows in `docs/qa-test-checklist.md` must be logged before M3 closure. | Berat Kaan Akcan | Record measured emulator timings and update the M3 test-run log in `docs/qa-test-checklist.md` by `21.11.2026`. |

---

## 3. Week 7 (`09.11.2026 – 15.11.2026`) Plan vs. Actual & Risk Review

| Dimension | Summary |
| :--- | :--- |
| **Planned for Week 7** | Begin Sprint 2 development for the Active Workout Logger (`WP-05`) and Workout History (`WP-06`), resolve routine follow-up `#45`, and prepare initial M3 status evidence. |
| **Actual in Week 7** | Completed routine rejected-write feedback (`#45`), extended `routine_order` boundary regression tests, updated Firebase deployment/emulator documentation ([#46](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/46)), and compiled this M3 status summary. Core `WP-05` and `WP-06` implementation moves into the second half of Sprint 2 (`15–20 Nov`). |
| **Cause of Deviation (`A-04` / `R-03`)** | University midterm exams during Week 7 reduced available development hours across the team (anticipated in Assumption `A-04` and Risk `R-03`). Because Sprint 1 was intentionally front-loaded (`30 SP` completed by `07.11.2026`), the team kept Week 7 tasks small and focused on hardening existing features rather than rushing unverified Sprint 2 code. |
| **Mitigation & Schedule Impact** | Sprint 2 remains focused strictly on `Must` deliverables (`WP-05` and `WP-06`). If exam-period velocity remains below nominal capacity in Sprint 3–4, secondary `Should` enhancements (`WP-08`: Starter Programs, Calendar View, Google Sign-In) remain first in the MoSCoW cut order. |

---

## 4. Updated Sprint 2 Priorities (`15.11.2026 – 22.11.2026`)

To meet the M3 Midterm Project Review exit criteria (100% of `Must` work packages passing the Definition of Done), Sprint 2 execution for `15–22 November 2026` is prioritized as follows:

| Priority | Work Item / Issue | Owner | Target Date | Deliverable & Acceptance Evidence |
| :---: | :--- | :--- | :---: | :--- |
| **1** | **WP-05 (`#7`, `#19`, `#20`): Active Workout Logger & Ghost Values (`16 SP`, Must)** | Çağatay Oruk | `20.11.2026` | Start workout from routine, log weight (`kg`) and reps per set, add/remove exercises dynamically, pre-fill previous-session ghost values in `< 200 ms`, persist completed sessions (`FirestoreWorkoutSessionRepository`), and display end-of-workout volume/set summary. |
| **2** | **WP-06 (`#8`, `#21`, `#22`): Workout History & Per-Exercise Progression (`10 SP`, Must)** | Berat Kaan Akcan | `20.11.2026` | Chronological list of completed workout sessions with set breakdown (`US-11`), per-exercise max weight and total volume progression view (`US-12`), and widget/repository tests. |
| **3** | **WP-04 Follow-up Verification (`#45` & Offline Checks)** | Doğukan Direksiz | `18.11.2026` | Verify rejected-write feedback and offline routine persistence on the Android emulator; assist with `WP-05` / `WP-06` UI integration reviews. |
| **4** | **M3 Quality Verification, Velocity Metrics & Midterm Report (`#27`)** | Mehmet Egemen Karagöz & Berat Kaan Akcan | `21–22.11.2026` | Execute full M3 test-run log against `docs/qa-test-checklist.md`, compile Sprint 1–2 Planned-vs-Actual velocity and burndown metrics, update the GitHub Project Board (`WP-01`–`WP-06` in `Done`), and submit the M3 Midterm Review Report and demo evidence. |

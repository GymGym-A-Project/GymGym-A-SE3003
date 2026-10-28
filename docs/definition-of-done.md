# Definition of Done (DoD)

- **Owner:** Berat Kaan Akcan (`230717052` — Quality and Test Lead)
- **Baseline:** M2 Project Plan Baseline Report (submitted 01.11.2026)
- **Applies to:** every Work Package (`WP-01` – `WP-08`) and every Pull Request targeting `main`
- **Enforced by:** the DoD checklist in [`.github/pull_request_template.md`](../.github/pull_request_template.md) and the CI workflow [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)
- **Test cases per criterion:** [QA Test Checklist (`docs/qa-test-checklist.md`)](qa-test-checklist.md)

A work package is **Done** only when all six items below are true. A PR author ticks a box only after the check has actually been performed. An unticked box blocks the merge unless the reviewer records in the PR why the item does not apply (for example, a docs-only PR has no screen to check on an emulator).

| # | Criterion | How it is verified | Who verifies |
| :---: | :--- | :--- | :--- |
| **(a)** | Code compiles without warnings and follows the Flutter/Dart lint rules. | **CI job `analyze-and-test`** runs `dart format --output=none --set-exit-if-changed lib test` and `flutter analyze --fatal-infos` (lint set: `flutter_lints`, see `analysis_options.yaml`). A red CI run blocks the merge. | CI (automatic); reviewer confirms that CI is green |
| **(b)** | The feature passes all specified Work Package acceptance criteria on an Android/iOS emulator. | **Manual emulator check** against the WP section of the [QA Test Checklist](qa-test-checklist.md). The author runs `flutter run` on an Android emulator (iOS Simulator where available), works through every `manual-emulator` row, and adds a screenshot or short note to the PR. Automated widget/integration tests listed for the WP must also pass. | PR author, then the QA Lead spot-checks |
| **(c)** | The PR is reviewed and approved by at least one teammate (Tech Lead or QA Lead). | **GitHub review:** at least one *Approve* from Çağatay Oruk (Tech Lead) or Berat Kaan Akcan (QA Lead), who is not the author. The author cannot approve their own PR. | Reviewer |
| **(d)** | Unit/validation tests pass. These tests are **mandatory** for the plateau detection rules and the AI whitelist filter. | **CI** runs `flutter test` (unit + widget tests). The Node test suites are **not yet in CI**, so the author runs them locally and pastes the result into the PR whenever `functions/` or `firestore.rules` change: `npm test` in `functions/` (whitelist, PII, timeout) and the Firestore rules tests in `test/firebase/`. A PR that changes the plateau rule engine (`WP-07`) must include passing tests for the 10 synthetic datasets (`TC-P01`–`TC-P10`). | CI + reviewer |
| **(e)** | Mandatory attributions are kept on the relevant screens: **"© Gym visual"** on the exercise library list and every exercise detail view, and **"Advisory only — not medical advice"** on the AI plateau analysis screen. | **Automated widget tests** assert the "© Gym visual" text on the list and detail screens (`test/features/exercises/`). The reviewer also checks visually on the emulator. Once the analyzer UI exists (`WP-07`, Sprint 3), a widget test must assert the advisory notice. | CI + reviewer |
| **(f)** | The related GitHub Project Board card is moved to **Done** with the PR evidence link. | **Manual board check:** after the merge, the author moves the card on the [Project Board](https://github.com/users/se-230717041/projects/1/views/1?layout_template=board) to *Done* and adds a link to the merged PR. The QA Lead checks the board at each sprint review. | PR author; QA Lead at sprint review |

## Notes

- **Docs-only and tooling-only PRs** still have to pass (a), (c) and (f). For (b), (d) and (e), the author may write "N/A — no app code changed" in the PR instead of ticking the box.
- **Defects found during DoD verification** are logged with the severity scale in the [QA Test Checklist](qa-test-checklist.md#defect-severity-scale). An open *Critical* defect means the WP is not Done.

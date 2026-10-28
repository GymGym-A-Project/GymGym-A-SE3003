# GymGym-A — Smart Workout Tracker & Analyzer

**SE3003 - Software Project Management**

GymGym-A is a cross-platform mobile application built for amateur gym-goers to track their workouts with low friction, apply progressive overload using previous-session **ghost values**, and identify training plateaus via a deterministic 30-day rule engine paired with an on-demand AI explanation layer.

- **Repository:** [https://github.com/GymGym-A-Project/GymGym-A-SE3003](https://github.com/GymGym-A-Project/GymGym-A-SE3003)
- **Project Board:** [https://github.com/users/se-230717041/projects/1/views/1?layout_template=board](https://github.com/users/se-230717041/projects/1/views/1?layout_template=board)

## Team GymGym-A

| Student ID | Name | Role |
| :--- | :--- | :--- |
| `230717063` | Mehmet Egemen Karagöz | Project Manager / Facilitator |
| `230717015` | Doğukan Direksiz | Product Owner Representative |
| `230717041` | Çağatay Oruk | Technical Lead |
| `230717052` | Berat Kaan Akcan | Quality and Test Lead |

## Tech Stack

- **Mobile Client:** Flutter (`3.47.5` stable, Dart 3), Riverpod (`flutter_riverpod`), `go_router`
- **Authentication & Storage:** Firebase Authentication, Cloud Firestore (offline persistence enabled)
- **Plateau Analyzer:** Local deterministic 30-day rule engine + Firebase Cloud Function proxy for Google Gemini Flash (152-ID whitelist validated, 4s timeout fallback)
- **Exercise Catalog:** Bundled static JSON subset (`assets/data/exercises.json`, `152` verified exercises across 6 primary muscle groups with `180x180` GIFs and thumbnails)

## Technical Decisions

| Topic | Decision |
| :--- | :--- |
| Flutter version | `3.47.5` stable, pinned in `.fvmrc` and CI |
| State management | Riverpod (`flutter_riverpod`) |
| Navigation | `go_router` with a signed-out redirect guard (`WP-02`) |
| Backend | Firebase Auth + Cloud Firestore (offline persistence on) |
| Exercise library | Statically bundled `152`-exercise JSON + `180x180` media (`assets/gifs/`, `assets/thumbs/`) |
| Lint & CI | `flutter_lints`; GitHub Actions runs `dart format`, `flutter analyze --fatal-infos`, and `flutter test` |

## Getting Started

All `152` curated exercise records (`assets/data/exercises.json`) and their `180x180` media assets (`assets/gifs/` and `assets/thumbs/`) are bundled in the repository, so the application runs offline out of the box:

```bash
flutter pub get
flutter run
```

To run with the local Firebase Auth & Firestore Emulator Suite during development:

```bash
firebase emulators:start --only auth,firestore --project demo-gymgym
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

See [docs/firebase-auth-and-domain.md](docs/firebase-auth-and-domain.md) for full emulator and test instructions.

## Dataset & Attribution

The curated exercise catalog (`assets/data/exercises.json`) and `180x180` media subset are derived from [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset) (pinned commit `7455efae41b330c265e7cd4b78dfa848e7ce5ebd`) using `scripts/clean_dataset.py`. To regenerate the JSON catalog or re-verify the media assets from source:

```bash
python scripts/clean_dataset.py --no-media   # regenerate JSON only
python scripts/clean_dataset.py              # regenerate JSON and re-verify 180x180 media
```

- **Exercise Data & Code:** Licensed under the **MIT License**.
- **Visual Media (`180x180` GIFs & Thumbnails):** **© Gym visual** ([https://gymvisual.com/](https://gymvisual.com/)). Bundled strictly for non-commercial academic course evaluation (`SE3003`) at unmodified `180x180` resolution, with mandatory `"© Gym visual"` attribution displayed on the Exercise Library screen, the Exercise Detail view, and this README (`R-01` & `A-03`).
- **Advisory Notice:** All plateau analysis outputs are for informational workout tracking only and do not constitute medical or professional coaching advice.

## Quality & Testing

- [Definition of Done (`docs/definition-of-done.md`)](docs/definition-of-done.md): the six criteria every Work Package and PR must meet, and how each one is verified.
- [QA Test Checklist (`docs/qa-test-checklist.md`)](docs/qa-test-checklist.md): test cases for each acceptance criterion in `WP-01`–`WP-08`, with automation status, the regression policy, the defect severity scale, how to run tests, and the M3 test-run log.

CI runs `dart format`, `flutter analyze --fatal-infos`, `flutter test` and the Firestore rules tests on every PR. The Cloud Functions tests and the emulator integration test are run locally; see the checklist for the commands.

## Project Documentation

- [Dataset Selection & Schema (`docs/dataset-selection.md`)](docs/dataset-selection.md)
- [Week 3 Competitor Review: Strong vs. Hevy (`docs/competitor-review.md`)](docs/competitor-review.md)
- [Week 3 Technical Spike Summary (`docs/spike-summary.md`)](docs/spike-summary.md)
- [Firebase, Authentication & Domain Contract (`docs/firebase-auth-and-domain.md`)](docs/firebase-auth-and-domain.md)
- [Planning Poker Estimation Log (`docs/planning-poker-estimates.md`)](docs/planning-poker-estimates.md)
- [Definition of Done (`docs/definition-of-done.md`)](docs/definition-of-done.md)
- [QA Test Checklist (`docs/qa-test-checklist.md`)](docs/qa-test-checklist.md)
- [Submitted Milestone Reports (`docs/reports/`)](docs/reports/)

# GymGym-A — Smart Workout Tracker & Analyzer

**SE3003 - Software Project Management**

GymGym-A is a cross-platform mobile application built for amateur gym-goers to track their workouts with low friction, apply progressive overload using previous-session **ghost values**, and identify training plateaus via a deterministic 30-day rule engine paired with an on-demand AI explanation layer.

## Team GymGym-A

| Student ID | Name | Role |
| :--- | :--- | :--- |
| `230717063` | Mehmet Egemen Karagöz | Project Manager / Facilitator |
| `230717015` | Doğukan Direksiz | Product Owner Representative |
| `230717041` | Çağatay Oruk | Technical Lead |
| `230717052` | Berat Kaan Akcan | Quality and Test Lead |

## Tech Stack

- **Mobile Client:** Flutter (Dart 3), Riverpod, `go_router`
- **Authentication & Storage:** Firebase Authentication, Cloud Firestore (offline persistence enabled)
- **Plateau Analyzer:** Local deterministic 30-day rule engine + Firebase Cloud Function proxy for Google Gemini Flash (152-ID whitelist validated, 4s timeout fallback)
- **Exercise Catalog:** Bundled static JSON subset (`assets/data/exercises.json`, `152` verified exercises across 6 primary muscle groups)

## Technical Decisions

| Topic | Decision |
| :--- | :--- |
| Flutter version | `3.47.5` stable, pinned in `.fvmrc` and CI |
| State management | Riverpod (`flutter_riverpod`) |
| Navigation | `go_router` with a signed-out redirect guard (WP-02) |
| Backend | Firebase Auth + Cloud Firestore (offline persistence on) |
| Exercise library | Bundled JSON + `180x180` media, not stored in Firestore |
| Lint | `flutter_lints`; CI runs `flutter analyze --fatal-infos` + `flutter test` |

## Getting Started

```bash
flutter pub get
python scripts/clean_dataset.py   # downloads exercise media (not committed)
flutter run
```

## Dataset & Attribution

The curated exercise catalog (`assets/data/exercises.json`) is generated from [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset) (pinned commit `7455efae41b330c265e7ce5ebd`) using `scripts/clean_dataset.py`:

```bash
python scripts/clean_dataset.py --no-media
```

The `180x180` GIFs and thumbnails are **not committed** (the repository is public and the media is © Gym visual). After cloning, download them into `assets/gifs/` and `assets/thumbs/` before running the app:

```bash
python scripts/clean_dataset.py
```

- **Exercise Data & Code:** Licensed under the **MIT License**.
- **Visual Media (`180x180` GIFs & Thumbnails):** **© Gym visual** ([https://gymvisual.com/](https://gymvisual.com/)). Used strictly for academic course purposes at original `180x180` resolution with mandatory attribution displayed in the application UI and documentation.
- **Advisory Notice:** All plateau analysis outputs are for informational workout tracking only and do not constitute medical or professional coaching advice.

See [docs/dataset-selection.md](docs/dataset-selection.md) for the complete 152-exercise breakdown and JSON schema.

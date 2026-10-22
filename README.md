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

## Dataset & Attribution

The curated exercise catalog (`assets/data/exercises.json`) is generated from [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset) (pinned commit `7455efae41b330c265e7ce5ebd`) using `scripts/clean_dataset.py`:

```bash
python scripts/clean_dataset.py --no-media
```

- **Exercise Data & Code:** Licensed under the **MIT License**.
- **Visual Media (`180x180` GIFs & Thumbnails):** **© Gym visual** ([https://gymvisual.com/](https://gymvisual.com/)). Used strictly for academic course purposes at original `180x180` resolution with mandatory attribution displayed in the application UI and documentation.
- **Advisory Notice:** All plateau analysis outputs are for informational workout tracking only and do not constitute medical or professional coaching advice.

See [docs/dataset-selection.md](docs/dataset-selection.md) for the complete 152-exercise breakdown and JSON schema.

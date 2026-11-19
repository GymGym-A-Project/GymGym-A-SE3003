# M3 demo evidence — redesigned app on an Android phone

Screenshots and a screen recording of the M3 demo flow, taken on **19.11.2026** after the UI redesign.
They are the evidence for Appendix A3 of the M3 report. Each caption names the acceptance criterion it shows.

| Item | Value |
| :--- | :--- |
| Device | Samsung SM-S711B, Android 16 (API 36), 1080 × 2340 |
| Build | Release APK (`flutter build apk --release`) |
| Code | `main` @ `957939a` (PRs #57, #59, #63) plus #64 (Google sign-in, sign out in the app bar) |
| Backend | Live Firebase project `gymgym-a` (Auth + Firestore), no emulators |
| Account | Test account `m3.demo.gymgyma@example.com`, created in the app for this run; 3 routines and one earlier Push Day workout were entered by hand so that ghost values exist |
| Captured with | `adb exec-out screencap -p` and `adb shell screenrecord`; screenshots here are scaled to 720 px wide |
| Captured by | Berat Kaan Akcan (QA Lead) |

## Demo recording

`GymGym-A_M3_Android_Demo_v2.mp4`: 2 min 29 s, H.264, 1080 × 2340, 10 MB, no sound.
Video files are not committed to Git (see `.gitignore`). The recording is attached to the
[`m3-review` release](https://github.com/GymGym-A-Project/GymGym-A-SE3003/releases/tag/m3-review)
and submitted with the M3 report.

Flow: sign in → exercise library (Chest filter) → exercise detail → routines → Push Day →
active workout with ghost values, sets confirmed with ✓ → summary → History → per-exercise progression.

This recording replaces the 30 s clip in [`docs/m3-android-demo.md`](../m3-android-demo.md) for the M3 report,
because it also covers sign-in and the exercise library. That earlier clip and its reproducible
emulator harness stay valid for the logger flow.

## Screenshots

| File | Work package | Caption |
| :--- | :--- | :--- |
| [`A3-01-sign-in.png`](screenshots/A3-01-sign-in.png) | WP-02, WP-08 | Email/password sign-in with Create account, password reset and Continue with Google. |
| [`A3-02-exercise-library.png`](screenshots/A3-02-exercise-library.png) | WP-03 | Library of 152 exercises with search, muscle-group chips and the "© Gym visual" credit. |
| [`A3-03-exercise-detail.png`](screenshots/A3-03-exercise-detail.png) | WP-03 | Exercise detail: the GIF is never shown above 180 × 180, with attribution, muscles and instructions. |
| [`A3-04-routines.png`](screenshots/A3-04-routines.png) | WP-04 | The user's routines in a reorderable list with exercise counts. |
| [`A3-05-routine-detail.png`](screenshots/A3-05-routine-detail.png) | WP-04 | Routine view with target sets and Start workout. |
| [`A3-06-logger-ghost-values.png`](screenshots/A3-06-logger-ghost-values.png) | WP-05 | The active workout shows the previous session's values as faint ghost hints (60 kg × 8). |
| [`A3-07-logger-sets-completed.png`](screenshots/A3-07-logger-sets-completed.png) | WP-05 | ✓ confirms the previous values in one tap; completed sets turn green and the volume and set counters update live. |
| [`A3-08-workout-summary.png`](screenshots/A3-08-workout-summary.png) | WP-05 | End-of-workout summary: 2,731 kg total volume, 12 sets, duration and 4 exercises. |
| [`A3-09-history.png`](screenshots/A3-09-history.png) | WP-06 | History lists completed workouts, newest first (PO decision D-4). |
| [`A3-10-history-session-detail.png`](screenshots/A3-10-history-session-detail.png) | WP-06 | Session breakdown with every set and the volume per exercise. |
| [`A3-11-exercise-progression.png`](screenshots/A3-11-exercise-progression.png) | WP-06 | Per-exercise progression with top weight, best set and volume by date. |

## Scope and limits

- The status bar shows the real time of the run; notification icons were hidden with Android's demo mode, which was switched off again afterwards.
- These captures show the UI on one phone. They do not replace the automated suites, the emulator runs or the device timings listed in the [QA checklist](../qa-test-checklist.md#test-run-log-m3).
- iOS is not shown (see decision D-1 in the M3 report).

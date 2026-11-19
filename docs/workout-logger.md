# Active workout logger (US-09)

Open a routine and select **Start workout**. The Workout tab copies the routine's
exercise order and target set counts. An existing unfinished workout is resumed
instead of being replaced. The original routine is never edited by the logger.

Each set requires finite kg >= 0 and a positive whole-number rep count. Bodyweight
sets use 0 kg. Decimal points and decimal commas are accepted for kg. Use **Add
set**, **Remove set** and the shared searchable exercise picker to change the
session. Keep at least one set per exercise and 1–15 distinct exercises.

## Device persistence and completion

The user-scoped `WorkoutDraftStore` serializes raw entries to device preferences
after each change, including incomplete or invalid input. Writes are serialized
to prevent an earlier keystroke from overwriting a later one. A new application
container restores the same session ID, start time, selected exercises and set
inputs. Drafts are local to this device and Firebase UID; they are not a
cross-device active-session feature. **Discard workout** requires confirmation.

**Finish workout** validates every set, records a UTC finish time, derives volume
from sets and queues the existing `WorkoutSessionRepository.save` operation.
The History provider immediately includes the completed session from the local
Firestore cache, including while offline. Pending writes sync after reconnecting.
The latest completed draft is retained on the device until the next workout is
started or it is discarded. **Retry saving workout** resubmits the same ID and
finish time; it does not create another history entry.

Server rejections are emitted through `writeFailures` and displayed as a message.
Offline `unavailable` errors are not treated as rejections. Device storage or
immediate repository errors leave a visible error/retry path. Corrupt device
drafts can be discarded after confirmation. Device preferences are not a backup
against app-data clearing or uninstalling the app.

## Validation

```powershell
flutter test test/features/logger test/data/firestore_workout_session_repository_test.dart
firebase emulators:exec --only "auth,firestore" --project gymgym-a "flutter test integration_test/workout_logger_test.dart -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true"
```

The integration test uses only local Firebase services. It exercises the real
Android preference store, recreates the app container, finishes offline, checks
the cached History entry, reconnects, and checks that the server accepts the
session under `firestore.rules`. An Android emulator must already be running.
Stop standalone Firebase emulators before using `emulators:exec`. Replace the
device ID as needed; quote the comma-separated service list in PowerShell.

Verified on 19 November 2026: `flutter test` **172/172 passed**,
`flutter analyze --no-pub --fatal-infos` reported no issues, and the Android
logger integration test **1/1 passed** on API 36.1. Other integration suites,
rules-only tests and Functions tests were not rerun for this change.
The Windows device run used an ASCII drive mapping, temporary non-incremental
Kotlin compilation and isolated Firebase ports with `adb reverse`; temporary
Gradle changes and port forwarding were removed afterwards. Explicit
`FIREBASE_EMULATOR_HOST` values are preserved by the bootstrap rather than
being remapped by the Firebase SDK a second time.

Ghost hints, last-performance storage, the completion summary and the <200 ms
ghost-value target belong to US-10 (#20) and are not implemented by this change.

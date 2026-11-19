# Workout logger and ghost values (US-09 / US-10)

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
The completion screen shows total volume (kg × reps), set count, duration and
exercise count. **View history** opens History explicitly. Bodyweight sets retain
0 kg volume; the separate plateau/bodyweight policy is unchanged.
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

## Previous-set hints (US-10)

Empty kg and reps fields show subdued hints from the most recently completed
session **for each exercise**, matching sets by position. Hints never become
input automatically: finishing with blank fields still fails validation, and
clearing an entry does not save its hint. **Complete set** explicitly accepts
previous values for empty fields while preserving any entered values. You can
edit accepted values before finishing. Additional sets have no hint or acceptance
button when no matching previous set exists.

`ghostValuesProvider` reads only the current user's native Firestore cache and
derives an immutable read model with `previousSets`. Only sessions completed by
the current workout's start time qualify. Ordering is finish time descending,
start time descending, then session ID ascending for ties. This prevents a
current or later workout becoming its own reference. History synchronization
refreshes hints asynchronously without blocking entry. On a new device, hints
remain unavailable until completed sessions have synced; missing cache entries
cannot be inferred offline. Loading and errors leave entry usable, with retry
for errors.

This uses workout history as the fallback source. It does not write
`lastPerformance`: that collection remains client-read-only under the existing
rules. No rules deployment is needed.

## Native profile acceptance

```powershell
firebase emulators:exec --only "auth,firestore" --project gymgym-a "flutter drive --profile --driver=test_driver/integration_test.dart --target=integration_test/ghost_values_test.dart -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true"
```

The dedicated test bootstraps local services before any data/auth operations;
production bootstrap continues to reject profile/release emulator flags.
Android profile network security permits HTTP only to loopback and `10.0.2.2`;
release configuration is unchanged. For isolated host ports, use `adb reverse`
and explicitly set `--dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1`.

The test seeds 60 completed sessions, disables networking, takes ten native
cache-read-plus-lookup samples and checks their median against 200 ms. This
measurement excludes navigation and animations. It also checks the rendered
hint, blank actual input, an offline finish/summary under one second, cached
History and subsequent server synchronization. Results are recorded in the QA
test-run log. This emulator result does not establish performance on all devices.

Verified on 19 November 2026 against main `7f6890c`: **183/183** Flutter tests,
clean format/static analysis, and **1/1** native profile acceptance on Android
API 36.1. Ten samples over 60 sessions gave a **56.783 ms** cache-read-plus-lookup
median (42.481–125.768 ms); the separate offline finish/summary action took
**366 ms**. The accepted previous set (79 kg × 8) produced 632 kg in the summary,
local History and the server after reconnection. Other integration suites,
rules-only tests and Functions tests were not rerun for US-10.

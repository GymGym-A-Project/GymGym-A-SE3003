# Firebase, authentication and remaining domain models

## Local setup

Use the SDK pinned in `.fvmrc` (Flutter 3.47.5 / Dart 3.13.4).

```powershell
$env:Path = 'C:\dev\flutter-3.47.5\bin;' + $env:Path
flutter pub get
firebase login --reauth
firebase projects:list
flutterfire configure --project=gymgym-a --platforms=android
```

Use the team's existing Firebase project, `gymgym-a` (`.firebaserc`). Android's
package is
`com.gymgyma.gymgym_a`; iOS's bundle ID is `com.gymgyma.gymgyma`.
The production bootstrap initializes the native default Firebase app using the
platform files produced by FlutterFire. Do not substitute emulator identifiers
for production configuration. Android is configured in the repository; iOS
Firebase options and `GoogleService-Info.plist` are still missing. The iOS bundle
ID alone does not mean iOS is ready to run.

### Verified production setup

The following checks were completed on **7 November 2026** for `gymgym-a`:

- Firestore `(default)` exists in `eur3` (created on 28 October 2026).
- Firebase Authentication Email/Password is enabled, with a password required.
- `firestore.rules` compiled successfully and was released to Cloud Firestore.
  The CLI reported that the uploaded rules already matched the local file.

These are dated verification results, not a claim that cloud settings cannot
change. PR [#44](https://github.com/GymGym-A-Project/GymGym-A-SE3003/pull/44)
also records Android emulator and production routine acceptance checks.
This rules deployment does not deploy Cloud Functions, indexes or the app.

### Production commands

Run the app without the emulator flag to connect to the configured project:

```powershell
flutter run
```

To check the database and release the reviewed local rules to the live project:

```powershell
firebase firestore:databases:list --project gymgym-a
firebase deploy --only firestore:rules --project gymgym-a
```

The deploy command changes the live project's security rules. It is not part
of emulator setup. Confirm the current Email/Password setting in Firebase
Console under Authentication > Sign-in method > Email/Password.

## Emulator development

```powershell
# Terminal 1: keep the local services running.
firebase emulators:start --only auth,firestore --project gymgym-a
# Terminal 2: launch the Android app against those local services.
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Debug emulator builds use Auth port 9099 and Firestore port 8080. Android reuses
the default app from `google-services.json`, so its emulators run as `gymgym-a`;
other platforms use the explicit demo project. Android's default host is
`10.0.2.2`; other hosts default to
`127.0.0.1`. Override with `--dart-define=FIREBASE_EMULATOR_HOST=<host>` when
needed. Release/profile builds reject the emulator switch. Firestore disk
persistence is enabled before any query. The emulator flag routes Auth and
Firestore to local services even though Android's project ID remains
`gymgym-a`. Do not use the project ID alone to decide whether a run is local;
check the emulator flag and service hosts. Keep both services running for
`flutter run`; the integration commands below start them via `emulators:exec`.
Android is the configured production target; iOS and
web production configuration are not included.

On Windows, if Java reports `Unable to establish loopback connection` from
`UnixDomainSockets`, use an existing ASCII temp directory:

```powershell
New-Item -ItemType Directory C:\dev\gymgym-java-tmp -Force
$env:JAVA_TOOL_OPTIONS = '-Djdk.net.unixdomain.tmpdir=C:\dev\gymgym-java-tmp'
```

If Android rejects a non-ASCII project path, run the build from a temporary
ASCII drive mapping without moving the repository:

```powershell
subst G: 'C:\Users\Çağatay\Desktop\gymgym-a'
Push-Location G:\
flutter build apk --debug --dart-define=USE_FIREBASE_EMULATORS=true
Pop-Location
subst G: /D
```

Choose an unused drive letter. Run integration commands from that same mapping
when needed, then remove the mapping after all commands finish.

## Tests

```powershell
flutter analyze --fatal-infos
flutter test
cd test/firebase
npm ci
cd ../..
firebase emulators:exec --only firestore --project demo-gymgym "node --test test/firebase/firestore.rules.test.js"
firebase emulators:exec --only auth,firestore --project gymgym-a "flutter test integration_test/firebase_auth_test.dart -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true"
firebase emulators:exec --only auth,firestore --project gymgym-a "flutter test integration_test/firestore_routine_repository_test.dart -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true"
```

The integration tests require an already running Android emulator; replace
`emulator-5554` with its device ID. Run each `emulators:exec` command with the
standalone Firebase services stopped, so it can own ports 8080 and 9099.
The auth test registers an account in the local Auth emulator, checks redirects
on login/logout, requests a password reset and reads a cached Firestore document
with the network disabled. The routine test checks rules acceptance, timestamp
serialization, offline writes and synchronization after reconnecting. Both
require `USE_FIREBASE_EMULATORS=true` and assert the Firestore host ends in
`:8080`. They must not be run against production. The rules-only Node test uses
the separate `demo-gymgym` project and does not launch the Android app.

## Domain contract

- `Routine` / `RoutineItem` and their repository remain unchanged.
- `SetEntry`: completed set, finite `weightKg >= 0`, integer `reps > 0`.
  Zero load supports bodyweight exercises. Volume is `weightKg * reps`.
- `WorkoutExercise`: exercise ID and immutable ordered set list. An empty set
  list is valid while logging a session.
- `WorkoutSession`: ID, routine ID, start time, optional finish time and 1–15
  ordered exercises with distinct IDs. Finish time cannot precede start time.
  Total volume and exercise IDs are derived, never trusted from JSON.
- `WorkoutSessionRepository`: watch/get/save/delete in one user's scope.
  Snapshots sort by newest start time, then ID. Fake instances are independent.
  `SetEntry` is embedded in a session, so it has no independent repository or ID.
- JSON dates use UTC ISO-8601, matching the Routine convention. A future
  Firestore adapter must convert dates to/from `Timestamp` at the storage
  boundary. The collection names follow the Week 3 spike:
  `users/{uid}/routines` and `users/{uid}/workouts`.

## Auth and security

`AuthRepository` isolates Firebase SDK types from the UI; tests inject a fake.
Production uses Firebase email/password auth, which restores the native SDK's
persisted session. The router listens to auth state changes without rebuilding
its navigation stack. Signed-out access redirects to `/auth`; successful login
restores a relative internal destination. Signed-out users cannot navigate back
into protected screens. Password reset messages do not reveal whether an email
exists. Submit actions are disabled while a request is pending; async callbacks
check whether the widget is still mounted.

Rules default to deny, isolate users by authenticated UID, validate routine
fields/items and workout top-level fields, and deny unknown collections.
`lastPerformance` is currently read-only for its owner; a future logger/backend
task must explicitly define its write validation. `FirestoreRoutineRepository`
persists routines to Firestore; workouts still use the fake repository, so a
production workout repository is a separate task.
Exercise screens and their existing attribution remain unchanged.

## Remaining prerequisites

- Each developer needs their own authenticated Firebase CLI session with access
  to `gymgym-a`; successful setup on one machine does not sign in teammates.
- Configure iOS with FlutterFire on an appropriate development machine and
  record simulator/device acceptance evidence before claiming iOS support.
- Keep emulator and production acceptance evidence current when Firebase code
  or rules change, and obtain teammate review before merging changes.

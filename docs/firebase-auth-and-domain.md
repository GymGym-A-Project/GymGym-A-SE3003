# Firebase, authentication and remaining domain models

## Local setup

Use the SDK pinned in `.fvmrc` (Flutter 3.47.5 / Dart 3.13.4).

```powershell
$env:Path = 'C:\dev\flutter-3.47.5\bin;' + $env:Path
flutter pub get
firebase login --reauth
firebase projects:list
flutterfire configure --project=<PROJECT_ID> --platforms=android,ios
```

Use the team's existing Firebase project. Android's package is
`com.gymgyma.gymgym_a`; iOS's bundle ID is `com.gymgyma.gymgyma`.
The production bootstrap initializes the native default Firebase app using the
platform files produced by FlutterFire. Do not substitute emulator identifiers
for production configuration. Enable Email/Password in Firebase Authentication
and create the project's Firestore database before a production-device check.
No rules, functions or application have been deployed by this implementation.

## Emulator development

```powershell
firebase emulators:start --only auth,firestore --project demo-gymgym
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Debug emulator builds use the explicit demo project, Auth port 9099 and Firestore
port 8080. Android's default host is `10.0.2.2`; other hosts default to
`127.0.0.1`. Override with `--dart-define=FIREBASE_EMULATOR_HOST=<host>` when
needed. Release/profile builds reject the emulator switch. Firestore disk
persistence is enabled before any query. Native mobile platforms are the
configured targets; web configuration is not included.

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
firebase emulators:exec --only auth,firestore --project demo-gymgym "flutter test integration_test/firebase_auth_test.dart -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true"
```

The integration test requires an already running Android emulator. It registers
an account in the demo Auth emulator, checks redirects on login/logout, requests
a password reset and reads a Firestore document with the network disabled.
It refuses to run against a production project.

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
task must explicitly define its write validation. The fake repositories do not
persist app data to Firestore; production data repositories are a separate task.
Exercise screens and their existing attribution remain unchanged.

## External prerequisites still requiring verification

- Firebase CLI authentication and the team's project ID.
- FlutterFire-generated native project configuration.
- Email/Password provider enabled and Firestore database created in that project.
- Production-device check and teammate review before merge.

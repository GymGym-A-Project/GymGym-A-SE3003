# M3 Android demo — 19 November 2026

Recorded on Android emulator API 36.1, based on main `41f6498`, with the
ghost-label visibility fix in this branch. This is a paced, automated recording
of the real Flutter UI against local Firebase Auth/Firestore, not a mockup or
manual test claim. It is a debug build, not a performance benchmark.

## Artifact and content

Local deliverable: `output/m3-demo/GymGym-A_M3_Android_Demo.mp4`.
Approximately 30 seconds, H.264 MP4, 540 × 1300, 30 fps, Turkish explanatory
captions in a separate band below the app. The recording is silent. Raw video,
stage screenshots, timing markers and decoded verification frames are also in
that ignored output folder. Video binaries are not committed to Git.

Final MP4 SHA-256:
`6ee10d1d12eca13bde2d5fd94df0d99dcd578170d4252bd82f3237c792ad82b1`.

| Approximate time | Evidence |
| --- | --- |
| 0–3 s | The seeded demo routine is listed. |
| 3–8 s | Routine details; Start workout opens the logger. |
| 8–12 s | Empty actual inputs display faint previous values: 60 kg and 8 reps. |
| 12–17 s | Complete set explicitly accepts those values. |
| 17–23 s | Offline completion shows 480 kg volume, one set, one exercise and duration. |
| 23–30 s | History contains the new workout and the seeded previous workout. |

The run additionally asserts that the new workout reaches the local Firestore
emulator server after reconnection. This synchronization assertion is in the
test log; it is not a Firebase console view in the video. The short demonstration
correctly displays a duration of `0 min` because it takes less than a minute.

The harness creates a unique local account and one prior session, then removes
its workouts, routine, device draft and account. Production data and Gemini are
not used. The video does not prove iOS acceptance, live Gemini integration or
the complete M3 feature checklist.

## Reproduce

Start an Android emulator first. In terminal 1, from the repo root:

```powershell
firebase emulators:exec --only "auth,firestore" --project gymgym-a "flutter drive --debug --driver=test_driver/integration_test.dart --target=integration_test/m3_demo_test.dart -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=RUN_M3_DEMO=true" > "$env:TEMP\gymgym-m3-demo-test.log" 2>&1
```

Immediately after starting terminal 1, run terminal 2:

```powershell
./scripts/record_m3_demo.ps1
```

The recorder waits for `M3_DEMO_READY`, captures 44 seconds and saves stage
screenshots/markers. Only one recording harness should run at a time. Never
reuse a stale ready log. The integration test is skipped unless `RUN_M3_DEMO`
is explicitly true and refuses non-debug/non-emulator use.

Render the final captioned video with an installed FFmpeg binary and Python:

```powershell
python scripts/render_m3_demo.py --ffmpeg C:/path/to/ffmpeg.exe
```

The renderer trims setup/cleanup, preserves app proportions, adds captions,
decodes the entire result for corruption checks and extracts verification PNGs.
Inspect those frames before sharing. A Windows Arial font is used by default;
pass `--font` for another font path if needed.

This Windows run used an ASCII drive mapping, temporary non-incremental Kotlin
compilation and isolated Firebase ports with adb reverse as described in
`docs/workout-logger.md`. Temporary Gradle changes and reverse mappings were
restored afterwards.

## Validation and visual fix

The first visual review exposed Material's default label behavior hiding ghost
placeholders while the field was unfocused. Both labels now always float above
their input, leaving previous kg/reps visible before tapping. The widget test
checks this decoration; the final recorded frames verify the actual rendering.

On 19 November: Flutter **189/189**, fatal-info analysis clean, demo integration
**1/1** passed. The final MP4 decoded fully and routine/ghost/summary/History
frames were visually checked. Functions/rules suites were not rerun for this
two-property UI change. This supplements the earlier US-09/US-10 QA evidence;
it does not replace full M3 regression.

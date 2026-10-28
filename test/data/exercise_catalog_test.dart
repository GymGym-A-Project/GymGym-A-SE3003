import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/exercise_catalog.dart';
import 'package:gymgym_a/data/models/exercise.dart';

const _attribution = '© Gym visual — https://gymvisual.com/';

const _muscleQuotas = {
  'chest': 26,
  'back': 28,
  'legs': 30,
  'shoulders': 24,
  'arms': 28,
  'core': 16,
};

/// Media is not committed (see README); file checks run only after
/// `python scripts/clean_dataset.py` has downloaded it.
bool get _mediaDownloaded =>
    Directory('assets/gifs').existsSync() &&
    Directory('assets/gifs').listSync().any((f) => f.path.endsWith('.gif'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> exercises;
  late Duration loadTime;

  setUpAll(() async {
    final stopwatch = Stopwatch()..start();
    exercises = await const ExerciseCatalog().load();
    stopwatch.stop();
    loadTime = stopwatch.elapsed;
    debugPrint('Exercise catalog load time: ${loadTime.inMilliseconds} ms');
  });

  test('contains exactly 152 exercises with unique ids', () {
    expect(exercises, hasLength(152));
    expect(exercises.map((e) => e.id).toSet(), hasLength(152));
  });

  test('covers 6 muscle groups with the agreed quotas', () {
    final counts = <String, int>{};
    for (final e in exercises) {
      counts[e.primaryMuscle] = (counts[e.primaryMuscle] ?? 0) + 1;
    }
    expect(counts, _muscleQuotas);
  });

  test('every record has its required fields and attribution', () {
    for (final e in exercises) {
      final reason = 'exercise ${e.id}';
      expect(e.id, isNotEmpty, reason: reason);
      expect(e.name, isNotEmpty, reason: reason);
      expect(e.targetMuscle, isNotEmpty, reason: reason);
      expect(e.equipment, isNotEmpty, reason: reason);
      expect(e.movementType, isIn(['compound', 'isolation']), reason: reason);
      expect(e.splitTags, isNotEmpty, reason: reason);
      expect(e.instructions['en'], isNotEmpty, reason: reason);
      expect(e.instructionSteps['en'], isNotEmpty, reason: reason);
      expect(e.gifPath, startsWith('assets/gifs/'), reason: reason);
      expect(e.thumbPath, startsWith('assets/thumbs/'), reason: reason);
      expect(e.mediaId, isNotEmpty, reason: reason);
      expect(e.attribution, _attribution, reason: reason);
    }
  });

  test(
    'every gifPath and thumbPath file exists',
    () {
      final missing = [
        for (final e in exercises) ...[
          if (!File(e.gifPath).existsSync()) e.gifPath,
          if (!File(e.thumbPath).existsSync()) e.thumbPath,
        ],
      ];
      expect(missing, isEmpty);
    },
    skip: _mediaDownloaded
        ? false
        : 'media not downloaded; run python scripts/clean_dataset.py',
  );

  test('loads within 500 ms (CI regression guard)', () {
    // The M2 baseline target is < 100 ms on an emulator/device in profile
    // mode (QA-WP01-06 in docs/qa-test-checklist.md). This test VM runs JIT
    // with a cold asset bundle and measured 56-132 ms locally, so asserting
    // 100 ms here would be flaky; 500 ms only catches large regressions.
    expect(loadTime, lessThan(const Duration(milliseconds: 500)));
  });

  test('round-trips through toJson/fromJson', () {
    final first = exercises.first;
    final copy = Exercise.fromJson(first.toJson());
    expect(copy.toJson(), first.toJson());
  });
}

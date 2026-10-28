import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/exercise_catalog.dart';
import 'package:gymgym_a/data/models/exercise.dart';
import 'package:gymgym_a/features/exercises/exercise_filter.dart';

const _muscleCounts = {
  MuscleFilter.all: 152,
  MuscleFilter.chest: 26,
  MuscleFilter.back: 28,
  MuscleFilter.legs: 30,
  MuscleFilter.shoulders: 24,
  MuscleFilter.arms: 28,
  MuscleFilter.core: 16,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> exercises;

  setUpAll(() async {
    exercises = await const ExerciseCatalog().load();
  });

  for (final entry in _muscleCounts.entries) {
    test('${entry.key.label} returns ${entry.value} exercises', () {
      final result = filterExercises(exercises, muscle: entry.key);
      expect(result, hasLength(entry.value));
      expect(result.every(entry.key.matches), isTrue);
    });
  }

  test('empty or blank query returns all exercises', () {
    expect(filterExercises(exercises), hasLength(152));
    expect(filterExercises(exercises, query: '   '), hasLength(152));
  });

  test('search is case-insensitive', () {
    final lower = filterExercises(exercises, query: 'bench');
    final upper = filterExercises(exercises, query: 'BENCH');
    final mixed = filterExercises(exercises, query: 'BeNcH');
    expect(lower, hasLength(12));
    expect(upper.map((e) => e.id), lower.map((e) => e.id));
    expect(mixed.map((e) => e.id), lower.map((e) => e.id));
  });

  test('search matches target muscle and equipment', () {
    expect(filterExercises(exercises, query: 'lats'), hasLength(12));
    expect(filterExercises(exercises, query: 'cable'), hasLength(29));
  });

  test('filter and search combine', () {
    final result = filterExercises(
      exercises,
      muscle: MuscleFilter.chest,
      query: 'Dumbbell',
    );
    expect(result, hasLength(6));
    expect(
      result.every((e) => e.primaryMuscle == 'chest'),
      isTrue,
      reason: 'muscle filter still applies while searching',
    );
  });

  test('no match returns an empty list', () {
    expect(filterExercises(exercises, query: 'zzz-no-such-exercise'), isEmpty);
    expect(
      filterExercises(exercises, muscle: MuscleFilter.legs, query: 'bench'),
      isEmpty,
    );
  });

  test('filter + search over 152 items takes under 150 ms', () {
    final stopwatch = Stopwatch()..start();
    filterExercises(exercises, muscle: MuscleFilter.chest, query: 'press');
    stopwatch.stop();
    debugPrint('Filter + search time: ${stopwatch.elapsedMicroseconds} µs');
    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 150)));
  });
}

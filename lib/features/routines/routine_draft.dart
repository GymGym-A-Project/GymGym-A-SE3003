import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/exercise.dart';
import '../../data/models/routine.dart';
import '../../data/models/routine_item.dart';

const maxRoutineExercises = 15;
const defaultTargetSets = 3;
const minTargetSets = 1;

/// A selected exercise and its planned set count.
class RoutineDraftItem {
  const RoutineDraftItem(this.exercise, {this.targetSets = defaultTargetSets});

  final Exercise exercise;
  final int targetSets;
}

/// The unsaved routine on the create and edit screens.
class RoutineDraft {
  const RoutineDraft({this.name = '', this.items = const []});

  /// A draft of [routine], keeping its exercise order. Exercises missing from
  /// [catalog] stay in the routine under a placeholder name.
  factory RoutineDraft.fromRoutine(Routine routine, List<Exercise> catalog) {
    final byId = {for (final exercise in catalog) exercise.id: exercise};
    final seen = <String>{};
    return RoutineDraft(
      name: routine.name,
      items: List.unmodifiable([
        for (final item in routine.items)
          if (seen.add(item.exerciseId))
            RoutineDraftItem(
              byId[item.exerciseId] ?? _unknownExercise(item.exerciseId),
              targetSets: item.targetSets,
            ),
      ]),
    );
  }

  final String name;
  final List<RoutineDraftItem> items;

  bool get isFull => items.length >= maxRoutineExercises;

  bool get canSave => name.trim().isNotEmpty && items.isNotEmpty;

  bool contains(String exerciseId) =>
      items.any((item) => item.exercise.id == exerciseId);

  /// Throws [ArgumentError] when the draft breaks a [Routine] rule.
  Routine toRoutine({
    required String id,
    required int order,
    required DateTime updatedAt,
    String source = 'custom',
  }) {
    return Routine(
      id: id,
      name: name.trim(),
      order: order,
      items: [
        for (final item in items)
          RoutineItem(
            exerciseId: item.exercise.id,
            targetSets: item.targetSets,
          ),
      ],
      source: source,
      updatedAt: updatedAt,
    );
  }
}

Exercise _unknownExercise(String id) => Exercise(
  id: id,
  name: 'Unknown exercise',
  primaryMuscle: '',
  targetMuscle: '',
  secondaryMuscles: const [],
  equipment: '',
  equipmentSource: '',
  movementType: '',
  splitTags: const [],
  instructions: const {},
  instructionSteps: const {},
  gifPath: '',
  thumbPath: '',
  mediaId: '',
  attribution: '',
);

class RoutineDraftNotifier extends Notifier<RoutineDraft> {
  @override
  RoutineDraft build() => const RoutineDraft();

  void load(RoutineDraft draft) => state = draft;

  void rename(String name) =>
      state = RoutineDraft(name: name, items: state.items);

  /// Adds [exercise] once. Returns false when the routine is full; an exercise
  /// that is already selected stays selected, because a workout session needs
  /// distinct exercises.
  bool add(Exercise exercise) {
    if (state.contains(exercise.id)) return true;
    if (state.isFull) return false;
    _setItems([...state.items, RoutineDraftItem(exercise)]);
    return true;
  }

  void remove(String exerciseId) => _setItems([
    for (final item in state.items)
      if (item.exercise.id != exerciseId) item,
  ]);

  /// Moves the item at [from] to index [to] of the list without that item.
  void move(int from, int to) {
    final items = [...state.items];
    items.insert(to, items.removeAt(from));
    _setItems(items);
  }

  /// Changes the target sets of [exerciseId] by [delta], never below the minimum.
  void changeTargetSets(String exerciseId, int delta) => _setItems([
    for (final item in state.items)
      if (item.exercise.id == exerciseId)
        RoutineDraftItem(
          item.exercise,
          targetSets: max(minTargetSets, item.targetSets + delta),
        )
      else
        item,
  ]);

  void _setItems(List<RoutineDraftItem> items) =>
      state = RoutineDraft(name: state.name, items: List.unmodifiable(items));
}

/// Lives only while the create or edit screen is open.
final routineDraftProvider =
    NotifierProvider.autoDispose<RoutineDraftNotifier, RoutineDraft>(
      RoutineDraftNotifier.new,
    );

final _random = Random();

/// Time-based id with a random suffix, so that two ids never collide in
/// practice even when created in the same microsecond.
String newRoutineId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

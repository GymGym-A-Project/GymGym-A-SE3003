import '../../data/models/routine.dart';
import '../../data/models/set_entry.dart';
import '../../data/models/workout_session.dart';

/// Raw input is retained, including blank/invalid fields, across app restarts.
class WorkoutSetDraft {
  const WorkoutSetDraft({required this.id, this.weight = '', this.reps = ''});
  final String id;
  final String weight;
  final String reps;

  double? get parsedWeight =>
      double.tryParse(weight.trim().replaceAll(',', '.'));
  int? get parsedReps => int.tryParse(reps.trim());
  String? get weightError {
    final value = parsedWeight;
    return value == null || !value.isFinite || value < 0
        ? 'Enter kg of 0 or more.'
        : null;
  }

  String? get repsError => parsedReps == null || parsedReps! <= 0
      ? 'Enter a whole number above 0.'
      : null;
  bool get isValid => weightError == null && repsError == null;
  SetEntry toEntry() {
    if (!isValid) {
      throw StateError('Complete every set with valid kg and reps.');
    }
    return SetEntry(weightKg: parsedWeight!, reps: parsedReps!);
  }

  Map<String, dynamic> toJson() => {'id': id, 'weight': weight, 'reps': reps};
  factory WorkoutSetDraft.fromJson(Map<String, dynamic> json) =>
      WorkoutSetDraft(
        id: json['id'] as String,
        weight: json['weight'] as String,
        reps: json['reps'] as String,
      );
}

class WorkoutExerciseDraft {
  WorkoutExerciseDraft({
    required this.exerciseId,
    required List<WorkoutSetDraft> sets,
  }) : sets = List.unmodifiable(sets) {
    if (exerciseId.trim().isEmpty || sets.isEmpty) {
      throw ArgumentError('An exercise needs an id and at least one set.');
    }
  }
  final String exerciseId;
  final List<WorkoutSetDraft> sets;
  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets.map((s) => s.toJson()).toList(),
  };
  factory WorkoutExerciseDraft.fromJson(Map<String, dynamic> json) =>
      WorkoutExerciseDraft(
        exerciseId: json['exerciseId'] as String,
        sets: (json['sets'] as List)
            .map((s) => WorkoutSetDraft.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class WorkoutDraft {
  WorkoutDraft({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startedAt,
    this.finishedAt,
    required List<WorkoutExerciseDraft> exercises,
  }) : exercises = List.unmodifiable(exercises) {
    if (id.isEmpty ||
        routineId.isEmpty ||
        exercises.isEmpty ||
        exercises.length > 15 ||
        exercises.map((e) => e.exerciseId).toSet().length != exercises.length) {
      throw ArgumentError('A workout needs 1–15 distinct exercises.');
    }
  }

  factory WorkoutDraft.fromRoutine(
    Routine routine, {
    required String id,
    required DateTime now,
  }) => WorkoutDraft(
    id: id,
    routineId: routine.id,
    routineName: routine.name,
    startedAt: now,
    exercises: [
      for (final item in routine.items)
        WorkoutExerciseDraft(
          exerciseId: item.exerciseId,
          sets: [
            for (var i = 0; i < item.targetSets; i++) WorkoutSetDraft(id: '$i'),
          ],
        ),
    ],
  );

  final String id;
  final String routineId;
  final String routineName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<WorkoutExerciseDraft> exercises;
  bool get isFinished => finishedAt != null;
  bool get isValid => exercises.every((e) => e.sets.every((s) => s.isValid));

  WorkoutDraft copyWith({
    List<WorkoutExerciseDraft>? exercises,
    DateTime? finishedAt,
  }) => WorkoutDraft(
    id: id,
    routineId: routineId,
    routineName: routineName,
    startedAt: startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    exercises: exercises ?? this.exercises,
  );

  WorkoutSession toSession() => WorkoutSession(
    id: id,
    routineId: routineId,
    startedAt: startedAt,
    finishedAt: finishedAt,
    exercises: [
      for (final e in exercises)
        WorkoutExercise(
          exerciseId: e.exerciseId,
          sets: e.sets.map((s) => s.toEntry()).toList(),
        ),
    ],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'routineId': routineId,
    'routineName': routineName,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt?.toUtc().toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
  factory WorkoutDraft.fromJson(Map<String, dynamic> json) => WorkoutDraft(
    id: json['id'] as String,
    routineId: json['routineId'] as String,
    routineName: json['routineName'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    finishedAt: json['finishedAt'] == null
        ? null
        : DateTime.parse(json['finishedAt'] as String),
    exercises: (json['exercises'] as List)
        .map((e) => WorkoutExerciseDraft.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

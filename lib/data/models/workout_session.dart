import 'set_entry.dart';

/// Exercise and set order are preserved, matching the Week 3 workout schema.
class WorkoutExercise {
  WorkoutExercise({required this.exerciseId, required List<SetEntry> sets})
    : sets = List.unmodifiable(sets) {
    if (exerciseId.trim().isEmpty) {
      throw ArgumentError.value(exerciseId, 'exerciseId', 'Must not be blank');
    }
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        exerciseId: json['exerciseId'] as String,
        sets: (json['sets'] as List)
            .map((set) => SetEntry.fromJson(set as Map<String, dynamic>))
            .toList(),
      );

  final String exerciseId;
  final List<SetEntry> sets;

  double get totalVolume => sets.fold(0, (sum, set) => sum + set.volume);

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets.map((set) => set.toJson()).toList(),
  };
}

/// An in-progress session has no [finishedAt]; empty set lists are allowed.
class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.routineId,
    required this.startedAt,
    this.finishedAt,
    required List<WorkoutExercise> exercises,
  }) : exercises = List.unmodifiable(exercises) {
    if (id.trim().isEmpty || routineId.trim().isEmpty) {
      throw ArgumentError('Session and routine ids must not be blank');
    }
    if (finishedAt != null && finishedAt!.isBefore(startedAt)) {
      throw ArgumentError('finishedAt must not precede startedAt');
    }
    if (this.exercises.isEmpty || this.exercises.length > 15) {
      throw ArgumentError('A workout must contain 1–15 exercises');
    }
    if (this.exercises.map((e) => e.exerciseId).toSet().length !=
        this.exercises.length) {
      throw ArgumentError('Workout exercise ids must be unique');
    }
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    routineId: json['routineId'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    finishedAt: json['finishedAt'] == null
        ? null
        : DateTime.parse(json['finishedAt'] as String),
    exercises: (json['exercises'] as List)
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final String id;
  final String routineId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<WorkoutExercise> exercises;

  double get totalVolume => exercises.fold(0, (sum, e) => sum + e.totalVolume);

  Map<String, dynamic> toJson() => {
    'id': id,
    'routineId': routineId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt?.toUtc().toIso8601String(),
    'exerciseIds': exercises.map((e) => e.exerciseId).toList(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'totalVolume': totalVolume,
  };
}

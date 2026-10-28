/// An exercise and its planned set count within a routine.
class RoutineItem {
  RoutineItem({required this.exerciseId, required this.targetSets}) {
    if (targetSets <= 0) {
      throw ArgumentError.value(targetSets, 'targetSets', 'Must be positive');
    }
  }

  factory RoutineItem.fromJson(Map<String, dynamic> json) => RoutineItem(
    exerciseId: json['exerciseId'] as String,
    targetSets: json['targetSets'] as int,
  );

  final String exerciseId;
  final int targetSets;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'targetSets': targetSets,
  };
}

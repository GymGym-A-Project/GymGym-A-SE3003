/// One completed set. Zero external load is valid for bodyweight exercises.
class SetEntry {
  SetEntry({required this.weightKg, required this.reps}) {
    if (!weightKg.isFinite || weightKg < 0) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Must be finite and >= 0',
      );
    }
    if (reps <= 0) {
      throw ArgumentError.value(reps, 'reps', 'Must be positive');
    }
  }

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
    weightKg: (json['weightKg'] as num).toDouble(),
    reps: json['reps'] as int,
  );

  final double weightKg;
  final int reps;

  double get volume => weightKg * reps;

  Map<String, dynamic> toJson() => {'weightKg': weightKg, 'reps': reps};
}

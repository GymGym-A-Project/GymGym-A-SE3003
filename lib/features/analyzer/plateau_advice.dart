import '../../data/models/exercise.dart';

const plateauDisclaimer = 'Advisory only - not medical or coaching advice';

/// An anonymous metric projection. Never serialize a WorkoutSession or user here.
class PlateauMetric {
  PlateauMetric({required this.maxWeightKg, required this.totalVolume}) {
    if (!maxWeightKg.isFinite ||
        maxWeightKg < 0 ||
        maxWeightKg > 10000 ||
        !totalVolume.isFinite ||
        totalVolume < 0 ||
        totalVolume > 100000000) {
      throw ArgumentError('Invalid plateau metric');
    }
  }
  final double maxWeightKg;
  final double totalVolume;
  Map<String, double> toJson() => {
    'maxWeightKg': maxWeightKg,
    'totalVolume': totalVolume,
  };
}

Map<String, Object> plateauRequest({
  required Map<String, List<PlateauMetric>> exercises,
  required Iterable<String> allowedExerciseIds,
  required List<Exercise> catalog,
}) {
  final known = catalog.map((e) => e.id).toSet();
  final included = exercises.entries
      .where((e) => known.contains(e.key) && e.value.isNotEmpty)
      .take(15)
      .toList();
  final currentIds = included.map((e) => e.key).toSet();
  return {
    'summary': {
      'exercises': [
        for (final e in included)
          {
            'exerciseId': e.key,
            'sessions': [
              for (final metric in e.value.skip(
                e.value.length > 60 ? e.value.length - 60 : 0,
              ))
                metric.toJson(),
            ],
          },
      ],
    },
    'allowedExerciseIds': allowedExerciseIds
        .where((id) => known.contains(id) && !currentIds.contains(id))
        .toSet()
        .toList(),
  };
}

class PlateauAdvice {
  PlateauAdvice._(
    this.explanation,
    this.isFallback,
    Iterable<Exercise> alternatives,
  ) : alternatives = List.unmodifiable(alternatives);

  /// Resolve IDs through the local library again; never display model-provided names.
  factory PlateauAdvice.fromJson(
    Map<String, dynamic> json, {
    required List<Exercise> catalog,
    required Set<String> allowedExerciseIds,
  }) {
    final known = {for (final e in catalog) e.id: e};
    final ids = json['alternatives'];
    final filtered = ids is List
        ? ids
              .whereType<String>()
              .where(
                (id) =>
                    known.containsKey(id) && allowedExerciseIds.contains(id),
              )
              .toSet()
              .take(3)
              .toList()
        : <String>[];
    final explanation = json['explanation'];
    final valid =
        json['source'] == 'gemini' &&
        explanation is String &&
        explanation.trim().isNotEmpty &&
        explanation.length <= 2000 &&
        filtered.length >= 2;
    return PlateauAdvice._(
      valid ? explanation.trim() : 'AI explanation is unavailable. Your rule-based plateau result is unchanged.',
      !valid,
      (valid ? filtered : allowedExerciseIds.where(known.containsKey).take(3))
          .map((id) => known[id]!),
    );
  }
  final String explanation;
  final bool isFallback;
  final List<Exercise> alternatives;
}

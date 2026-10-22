/// One entry of the bundled exercise catalog (`assets/data/exercises.json`).
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    this.nameTr,
    required this.primaryMuscle,
    required this.targetMuscle,
    required this.secondaryMuscles,
    required this.equipment,
    required this.equipmentSource,
    required this.movementType,
    required this.splitTags,
    required this.instructions,
    required this.instructionSteps,
    required this.gifPath,
    required this.thumbPath,
    required this.mediaId,
    required this.attribution,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      nameTr: json['nameTr'] as String?,
      primaryMuscle: json['primaryMuscle'] as String,
      targetMuscle: json['targetMuscle'] as String,
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] as List),
      equipment: json['equipment'] as String,
      equipmentSource: json['equipmentSource'] as String,
      movementType: json['movementType'] as String,
      splitTags: List<String>.from(json['splitTags'] as List),
      instructions: Map<String, String>.from(json['instructions'] as Map),
      instructionSteps: (json['instructionSteps'] as Map).map(
        (lang, steps) =>
            MapEntry(lang as String, List<String>.from(steps as List)),
      ),
      gifPath: json['gifPath'] as String,
      thumbPath: json['thumbPath'] as String,
      mediaId: json['mediaId'] as String,
      attribution: json['attribution'] as String,
    );
  }

  final String id;
  final String name;
  final String? nameTr;

  /// One of: chest, back, legs, shoulders, arms, core.
  final String primaryMuscle;
  final String targetMuscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final String equipmentSource;

  /// `compound` or `isolation`.
  final String movementType;
  final List<String> splitTags;

  /// Keyed by language code (`en`, `tr`).
  final Map<String, String> instructions;
  final Map<String, List<String>> instructionSteps;
  final String gifPath;
  final String thumbPath;
  final String mediaId;
  final String attribution;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameTr': nameTr,
    'primaryMuscle': primaryMuscle,
    'targetMuscle': targetMuscle,
    'secondaryMuscles': secondaryMuscles,
    'equipment': equipment,
    'equipmentSource': equipmentSource,
    'movementType': movementType,
    'splitTags': splitTags,
    'instructions': instructions,
    'instructionSteps': instructionSteps,
    'gifPath': gifPath,
    'thumbPath': thumbPath,
    'mediaId': mediaId,
    'attribution': attribution,
  };
}

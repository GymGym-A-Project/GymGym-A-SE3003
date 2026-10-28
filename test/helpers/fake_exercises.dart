import 'package:gymgym_a/data/models/exercise.dart';

const fakeAttribution = '© Gym visual — https://gymvisual.com/';

/// Minimal exercise for widget tests. Media paths do not exist, so images
/// render through their errorBuilder.
Exercise fakeExercise({
  required String id,
  required String name,
  required String primaryMuscle,
  String targetMuscle = 'target',
  String equipment = 'barbell',
  List<String> secondaryMuscles = const [],
  Map<String, List<String>> instructionSteps = const {'en': []},
}) {
  return Exercise(
    id: id,
    name: name,
    primaryMuscle: primaryMuscle,
    targetMuscle: targetMuscle,
    secondaryMuscles: secondaryMuscles,
    equipment: equipment,
    equipmentSource: equipment,
    movementType: 'compound',
    splitTags: const [],
    instructions: const {'en': ''},
    instructionSteps: instructionSteps,
    gifPath: 'test/missing/$id.gif',
    thumbPath: 'test/missing/$id.jpg',
    mediaId: id,
    attribution: fakeAttribution,
  );
}

final fakeExercises = [
  fakeExercise(
    id: '1',
    name: 'Bench Press',
    primaryMuscle: 'chest',
    targetMuscle: 'pectorals',
    secondaryMuscles: ['shoulders', 'triceps'],
    instructionSteps: {
      'en': ['Lie on the bench.', 'Press the bar up.'],
      'tr': ['Banka uzanın.', 'Barı yukarı itin.'],
    },
  ),
  fakeExercise(
    id: '2',
    name: 'Lat Pulldown',
    primaryMuscle: 'back',
    targetMuscle: 'lats',
    equipment: 'cable',
  ),
  fakeExercise(
    id: '3',
    name: 'Barbell Squat',
    primaryMuscle: 'legs',
    targetMuscle: 'quads',
  ),
];

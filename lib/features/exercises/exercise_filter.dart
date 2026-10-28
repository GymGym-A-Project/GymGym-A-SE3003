import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/exercise_catalog.dart';
import '../../data/models/exercise.dart';

/// Muscle group chips on the library screen; [all] disables the filter.
enum MuscleFilter {
  all('All'),
  chest('Chest'),
  back('Back'),
  legs('Legs'),
  shoulders('Shoulders'),
  arms('Arms'),
  core('Core');

  const MuscleFilter(this.label);

  final String label;

  bool matches(Exercise exercise) =>
      this == all || exercise.primaryMuscle == name;
}

/// Returns the exercises in [muscle] whose name, Turkish name, target muscle
/// or equipment contains [query] (case-insensitive). Keeps catalog order.
List<Exercise> filterExercises(
  List<Exercise> exercises, {
  MuscleFilter muscle = MuscleFilter.all,
  String query = '',
}) {
  final needle = query.trim().toLowerCase();
  return exercises
      .where((e) => muscle.matches(e) && _matchesQuery(e, needle))
      .toList(growable: false);
}

bool _matchesQuery(Exercise exercise, String needle) {
  if (needle.isEmpty) return true;
  return [
    exercise.name,
    exercise.nameTr,
    exercise.targetMuscle,
    exercise.equipment,
  ].any((field) => field != null && field.toLowerCase().contains(needle));
}

class SelectedMuscle extends Notifier<MuscleFilter> {
  @override
  MuscleFilter build() => MuscleFilter.all;

  void select(MuscleFilter muscle) => state = muscle;
}

final selectedMuscleProvider = NotifierProvider<SelectedMuscle, MuscleFilter>(
  SelectedMuscle.new,
);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

/// The catalog after applying the selected muscle and search query.
final filteredExercisesProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final muscle = ref.watch(selectedMuscleProvider);
  final query = ref.watch(searchQueryProvider);
  return ref
      .watch(exerciseCatalogProvider)
      .whenData((all) => filterExercises(all, muscle: muscle, query: query));
});

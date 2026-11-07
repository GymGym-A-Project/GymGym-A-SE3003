import '../../data/models/routine.dart';

/// The order that places a new routine after [routines], which must be sorted
/// by order. Counting them would collide once a routine has been deleted.
int nextRoutineOrder(List<Routine> routines) =>
    routines.isEmpty ? 0 : routines.last.order + 1;

/// Moves the routine at [from] to index [to] and numbers the list by position.
///
/// Routines that keep their order stay the same instances, so a caller only has
/// to save the ones that changed.
List<Routine> reorderRoutines(
  List<Routine> routines,
  int from,
  int to, {
  required DateTime updatedAt,
}) {
  final moved = [...routines];
  moved.insert(to, moved.removeAt(from));
  return [
    for (final (index, routine) in moved.indexed)
      if (routine.order == index)
        routine
      else
        Routine(
          id: routine.id,
          name: routine.name,
          order: index,
          items: routine.items,
          source: routine.source,
          updatedAt: updatedAt,
        ),
  ];
}

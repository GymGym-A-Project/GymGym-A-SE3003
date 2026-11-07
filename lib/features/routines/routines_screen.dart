import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/routine_providers.dart';
import 'routine_order.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.routineNew),
        icon: const Icon(Icons.add),
        label: const Text('New routine'),
      ),
      body: ref
          .watch(routineListProvider)
          .when(
            data: (routines) => routines.isEmpty
                ? const Center(child: Text('No routines yet'))
                : _RoutineList(routines),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Could not load: $error')),
          ),
    );
  }
}

class _RoutineList extends ConsumerStatefulWidget {
  const _RoutineList(this.routines);

  final List<Routine> routines;

  @override
  ConsumerState<_RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends ConsumerState<_RoutineList> {
  /// The dropped order, shown until the repository reports it. Without it the
  /// tiles would jump while each changed routine is saved one by one.
  List<Routine>? _dropped;

  @override
  void didUpdateWidget(_RoutineList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dropped = _dropped;
    if (dropped == null) return;
    final ids = widget.routines.map((routine) => routine.id).toList();
    final settled =
        ids.length != dropped.length ||
        dropped.indexed.every((entry) => entry.$2.id == ids[entry.$1]);
    if (settled) _dropped = null;
  }

  Future<void> _reorder(int from, int to) async {
    if (from == to) return;
    final routines = _dropped ?? widget.routines;
    final reordered = reorderRoutines(
      routines,
      from,
      to,
      updatedAt: DateTime.now(),
    );
    setState(() => _dropped = reordered);
    try {
      final repository = ref.read(routineRepositoryProvider);
      if (repository == null) throw StateError('Not signed in');
      for (final routine in reordered) {
        if (!routines.contains(routine)) await repository.save(routine);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _dropped = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the new order. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routines = _dropped ?? widget.routines;
    return ReorderableListView.builder(
      // Keeps the last tile clear of the floating button.
      padding: const EdgeInsets.only(bottom: 88),
      buildDefaultDragHandles: false,
      itemCount: routines.length,
      itemBuilder: (context, index) => _RoutineTile(
        routines[index],
        index: index,
        key: ValueKey(routines[index].id),
      ),
      onReorderItem: _reorder,
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile(this.routine, {super.key, required this.index});

  final Routine routine;
  final int index;

  @override
  Widget build(BuildContext context) {
    final count = routine.items.length;
    return ListTile(
      leading: ReorderableDragStartListener(
        index: index,
        child: Icon(Icons.drag_handle, key: ValueKey('drag-${routine.id}')),
      ),
      title: Text(routine.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(count == 1 ? '1 exercise' : '$count exercises'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(AppRoutes.routineDetail(routine.id)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/routine_providers.dart';

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
                : ListView.builder(
                    // Keeps the last tile clear of the floating button.
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: routines.length,
                    itemBuilder: (context, index) =>
                        _RoutineTile(routines[index]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Could not load: $error')),
          ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile(this.routine);

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final count = routine.items.length;
    return ListTile(
      title: Text(routine.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(count == 1 ? '1 exercise' : '$count exercises'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(AppRoutes.routineDetail(routine.id)),
    );
  }
}

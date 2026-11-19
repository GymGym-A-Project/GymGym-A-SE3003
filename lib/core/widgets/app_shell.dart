import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/gaps.dart';
import '../theme/gym_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating bar, inset 12 from the screen edges.
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: Radii.sheetBorder,
                  border: Border.all(color: colors.border),
                ),
                child: ClipRRect(
                  borderRadius: Radii.sheetBorder,
                  child: NavigationBar(
                    selectedIndex: shell.currentIndex,
                    onDestinationSelected: (index) => shell.goBranch(
                      index,
                      initialLocation: index == shell.currentIndex,
                    ),
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.fitness_center),
                        label: 'Exercises',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.list_alt),
                        label: 'Routines',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.timer),
                        label: 'Workout',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.history),
                        label: 'History',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.insights),
                        label: 'Analyzer',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

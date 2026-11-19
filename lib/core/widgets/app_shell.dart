import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth/auth_providers.dart';
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
            const _SignOutButton(),
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

class _SignOutButton extends ConsumerStatefulWidget {
  const _SignOutButton();
  @override
  ConsumerState<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<_SignOutButton> {
  bool _busy = false;
  Future<void> _signOut() async {
    setState(() {
      _busy = true;
    });
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to sign out. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.only(right: Gap.s),
      child: TextButton.icon(
        onPressed: _busy ? null : _signOut,
        style: TextButton.styleFrom(
          foregroundColor: GymColors.of(context).textMuted,
          minimumSize: const Size(48, 40),
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sign out'),
      ),
    ),
  );
}

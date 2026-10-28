import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/app.dart';
import 'package:gymgym_a/data/exercise_catalog.dart';
import 'package:gymgym_a/data/models/exercise.dart';

void main() {
  testWidgets('app starts with bottom navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseCatalogProvider.overrideWith(
            (ref) async => const <Exercise>[],
          ),
        ],
        child: const GymGymApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('0 exercises loaded'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('History — coming soon'), findsOneWidget);
  });
}

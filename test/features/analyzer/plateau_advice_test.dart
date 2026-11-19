import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/exercise_catalog.dart';
import 'package:gymgym_a/features/analyzer/analyzer_screen.dart';
import 'package:gymgym_a/features/analyzer/plateau_advice.dart';
import 'package:gymgym_a/features/analyzer/plateau_advice_card.dart';

void main() {
  final catalog = ExerciseCatalog.parse(
    File('assets/data/exercises.json').readAsStringSync(),
  );
  final allowed = {'0030', '0033', '0003'};
  test('anonymous request contains only known IDs and numeric metrics', () {
    final request = plateauRequest(
      exercises: {
        '0025': [PlateauMetric(maxWeightKg: 60, totalVolume: 480)],
        'private@example.com': [
          PlateauMetric(maxWeightKg: 10, totalVolume: 100),
        ],
      },
      allowedExerciseIds: [...allowed, '0025', 'unknown'],
      catalog: catalog,
    );
    final encoded = jsonEncode(request);
    expect(encoded, isNot(contains('private')));
    expect(encoded, isNot(contains('unknown')));
    expect(request['allowedExerciseIds'], allowed.toList());
    expect(encoded, contains('"totalVolume":480.0'));
    expect(
      () => PlateauMetric(maxWeightKg: double.nan, totalVolume: 1),
      throwsArgumentError,
    );
    expect(
      () => PlateauMetric(maxWeightKg: 1, totalVolume: -1),
      throwsArgumentError,
    );
  });
  test('responses resolve only requested known IDs with local names', () {
    final advice = PlateauAdvice.fromJson(
      {
        'source': 'gemini',
        'explanation': 'Your metrics remain similar.',
        'alternatives': ['0030', '0030', 'unknown', '0025', '0033'],
        'disclaimer': 'untrusted text',
      },
      catalog: catalog,
      allowedExerciseIds: allowed,
    );
    expect(advice.isFallback, isFalse);
    expect(advice.alternatives.map((e) => e.id), ['0030', '0033']);
    expect(() => advice.alternatives.clear(), throwsUnsupportedError);
  });
  test('malformed responses deterministically use local fallback', () {
    for (final response in <Map<String, dynamic>>[
      {},
      {'source': 'fallback'},
      {
        'source': 'gemini',
        'explanation': {},
        'alternatives': ['0030', '0033'],
      },
      {
        'source': 'gemini',
        'explanation': 'text',
        'alternatives': ['unknown'],
      },
    ]) {
      final advice = PlateauAdvice.fromJson(
        response,
        catalog: catalog,
        allowedExerciseIds: allowed,
      );
      expect(advice.isFallback, isTrue);
      expect(advice.alternatives.map((e) => e.id), allowed.toList());
    }
  });
  for (final fallback in [false, true]) {
    testWidgets('advisory is visible on ${fallback ? "fallback" : "AI"} card', (
      tester,
    ) async {
      final advice = PlateauAdvice.fromJson(
        {
          'source': fallback ? 'fallback' : 'gemini',
          'explanation': 'Your metrics remain similar.',
          'alternatives': allowed.toList(),
        },
        catalog: catalog,
        allowedExerciseIds: allowed,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlateauAdviceCard(advice: advice),
            ),
          ),
        ),
      );
      expect(find.text(plateauDisclaimer), findsOneWidget);
      expect(
        find.text(catalog.firstWhere((e) => e.id == '0030').name),
        findsOneWidget,
      );
      expect(find.text('unknown'), findsNothing);
    });
  }
  testWidgets('analyzer entry always displays the mandatory advisory', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AnalyzerScreen()));
    expect(find.text(plateauDisclaimer), findsOneWidget);
  });
}

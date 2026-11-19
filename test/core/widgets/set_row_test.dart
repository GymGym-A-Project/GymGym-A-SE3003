import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/theme/app_theme.dart';
import 'package:gymgym_a/core/theme/gym_colors.dart';
import 'package:gymgym_a/core/widgets/set_row.dart';

class _Harness extends StatefulWidget {
  const _Harness({this.ghost = true});
  final bool ghost;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String weight = '';
  String reps = '';
  bool get valid =>
      (double.tryParse(weight) ?? -1) >= 0 && (int.tryParse(reps) ?? 0) > 0;

  @override
  Widget build(BuildContext context) => SetRow(
    number: 1,
    weight: weight,
    reps: reps,
    weightKey: const ValueKey('w'),
    repsKey: const ValueKey('r'),
    completeKey: const ValueKey('c'),
    ghostWeight: widget.ghost ? '60' : null,
    ghostReps: widget.ghost ? '8' : null,
    completed: valid,
    onWeightChanged: (v) => setState(() => weight = v),
    onRepsChanged: (v) => setState(() => reps = v),
    onComplete: widget.ghost
        ? () => setState(() {
            if (weight.isEmpty) weight = '60';
            if (reps.isEmpty) reps = '8';
          })
        : null,
  );
}

Future<void> _pump(WidgetTester tester, {bool ghost = true}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: _Harness(ghost: ghost)),
      ),
    );

TextField _field(WidgetTester tester, String key) => tester.widget<TextField>(
  find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  ),
);

void main() {
  testWidgets('ghost values are faint hints, not field text', (tester) async {
    await _pump(tester);
    final weight = _field(tester, 'w');
    expect(weight.controller!.text, '');
    expect(weight.decoration!.hintText, '60');
    expect(weight.decoration!.hintStyle!.color, GymColors.dark.ghost);
    expect(
      weight.decoration!.floatingLabelBehavior,
      FloatingLabelBehavior.always,
    );
    expect(_field(tester, 'r').decoration!.hintText, '8');
  });

  testWidgets('✓ confirms the ghost values and the row turns green', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('c')));
    await tester.pumpAndSettle();
    expect(_field(tester, 'w').controller!.text, '60');
    expect(_field(tester, 'r').controller!.text, '8');
    final box = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(
      (box.decoration! as BoxDecoration).color,
      GymColors.dark.successSurface,
    );
  });

  testWidgets('without a previous value there is no ✓ button', (tester) async {
    await _pump(tester, ghost: false);
    expect(find.byKey(const ValueKey('c')), findsNothing);
    expect(find.byTooltip('Remove set'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('w')), '0');
    await tester.enterText(find.byKey(const ValueKey('r')), '12');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}

import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/gym_colors.dart';

/// Number input that shows the previous session's value as a faint ghost.
///
/// The ghost is only a hint: it is never written into the field by itself, so
/// a blank field stays blank (and invalid) until the user types a value or
/// confirms the ghost with the set ✓. Entered values turn into the normal text
/// colour and a bold weight. External changes to [value] (for example a ✓
/// confirmation) update the visible text without losing the cursor.
class GhostNumberField extends StatefulWidget {
  const GhostNumberField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.ghost,
    this.errorText,
    this.decimal = false,
  });

  final String value;
  final String label;
  final ValueChanged<String> onChanged;

  /// Previous-session value, or null when there is none.
  final String? ghost;
  final String? errorText;

  /// Allows a decimal separator (kg); reps are whole numbers.
  final bool decimal;

  @override
  State<GhostNumberField> createState() => _GhostNumberFieldState();
}

class _GhostNumberFieldState extends State<GhostNumberField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant GhostNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    final number = AppText.headline.copyWith(fontFeatures: AppText.tabular);
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      textAlign: TextAlign.center,
      style: number.copyWith(color: colors.text, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: widget.label,
        // Keeps the ghost visible before the field is focused.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: widget.ghost,
        hintStyle: number.copyWith(
          color: colors.ghost,
          fontWeight: FontWeight.w700,
        ),
        errorText: widget.errorText,
        errorMaxLines: 3,
      ),
      onChanged: widget.onChanged,
    );
  }
}

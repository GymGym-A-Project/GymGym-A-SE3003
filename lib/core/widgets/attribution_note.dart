import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/gaps.dart';
import '../theme/gym_colors.dart';

/// The mandatory "© Gym visual" media credit (R-01). Shown wherever exercise
/// media appears.
class AttributionNote extends StatelessWidget {
  const AttributionNote(this.text, {super.key, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.s),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: AppText.body.copyWith(fontSize: 12, color: colors.textMuted),
      ),
    );
  }
}

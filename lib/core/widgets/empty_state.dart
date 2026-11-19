import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/gaps.dart';
import '../theme/gym_colors.dart';

/// One look for empty lists, errors and offline states.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// For example a button that leads to the next step.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.kor, size: 30),
            ),
            Gap.vL,
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.headline.copyWith(color: colors.text),
            ),
            if (message != null) ...[
              Gap.vS,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: colors.textMuted),
              ),
            ],
            if (action != null) ...[Gap.vL, action!],
          ],
        ),
      ),
    );
  }
}

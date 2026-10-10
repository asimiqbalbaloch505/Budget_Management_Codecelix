import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class BudgetProgress extends StatelessWidget {
  final double percentage;
  final double height;
  final Color? overrideColor;
  final Color? backgroundColor;

  const BudgetProgress({
    super.key,
    required this.percentage,
    this.height = 8.0,
    this.overrideColor,
    this.backgroundColor,
  });

  Color _getStatusColor() {
    if (overrideColor != null) return overrideColor!;
    if (percentage >= 100.0) return AppColors.danger;
    if (percentage >= 90.0) return AppColors.warning;
    if (percentage >= 70.0) return AppColors.primary;
    return AppColors.safe;
  }

  @override
  Widget build(BuildContext context) {
    final clampedFraction = (percentage / 100.0).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0));
    final barColor = _getStatusColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final fillWidth = totalWidth * clampedFraction;

        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: double.infinity,
            color: bg,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                width: fillWidth,
                height: height,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

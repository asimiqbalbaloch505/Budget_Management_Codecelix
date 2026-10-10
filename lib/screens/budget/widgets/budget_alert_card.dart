import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../models/budget_model.dart';
import '../models/category_budget_model.dart';

class BudgetAlertCard extends StatelessWidget {
  final BudgetModel budget;
  final String currencySymbol;
  final VoidCallback? onDismiss;

  const BudgetAlertCard({
    super.key,
    required this.budget,
    this.currencySymbol = 'PKR ',
    this.onDismiss,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_US');
    return '$currencySymbol${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    // Determine the most critical alert to display
    final isBudgetExceeded = budget.isExceeded;
    final exceededCategory = budget.categoryBudgets.firstWhere(
      (c) => c.healthState == BudgetHealthState.exceeded,
      orElse: () => const CategoryBudgetModel(
        categoryId: -1,
        categoryName: '',
        limitAmount: 0,
        spentAmount: 0,
      ),
    );

    final warningCategory = budget.categoryBudgets.firstWhere(
      (c) => c.healthState == BudgetHealthState.critical || c.percentageUsed >= 85,
      orElse: () => const CategoryBudgetModel(
        categoryId: -1,
        categoryName: '',
        limitAmount: 0,
        spentAmount: 0,
      ),
    );

    // If no alert is active, return SizedBox.shrink()
    if (!isBudgetExceeded && exceededCategory.categoryId == -1 && warningCategory.categoryId == -1) {
      return const SizedBox.shrink();
    }

    String message;
    Color bgColor;
    Color iconColor;
    Color borderColor;

    if (isBudgetExceeded) {
      message = 'You have exceeded your monthly budget by ${_formatAmount(budget.exceededAmount)}.';
      bgColor = AppColors.dangerLight;
      iconColor = AppColors.danger;
      borderColor = const Color(0xFFFECDD3);
    } else if (exceededCategory.categoryId != -1) {
      message = '${exceededCategory.categoryName} budget exceeded! You spent ${_formatAmount(exceededCategory.spentAmount)} of ${_formatAmount(exceededCategory.limitAmount)}.';
      bgColor = AppColors.dangerLight;
      iconColor = AppColors.danger;
      borderColor = const Color(0xFFFECDD3);
    } else {
      // Screen 9 exact mockup: "Bills are at 87% of your category budget."
      message = '${warningCategory.categoryName} are at ${warningCategory.percentageUsed.round()}% of your category budget.';
      bgColor = AppColors.dangerLight;
      iconColor = AppColors.danger;
      borderColor = const Color(0xFFFECDD3);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: iconColor,
                height: 1.3,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 16,
                color: iconColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

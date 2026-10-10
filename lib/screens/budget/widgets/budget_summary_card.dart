import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../models/budget_model.dart';
import '../models/category_budget_model.dart';
import 'budget_progress.dart';

class BudgetSummaryCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onEditBudget;
  final String currencySymbol;

  const BudgetSummaryCard({
    super.key,
    required this.budget,
    required this.onEditBudget,
    this.currencySymbol = 'PKR ',
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_US');
    return '$currencySymbol${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExceeded = budget.isExceeded;
    final isNearLimit = budget.healthState == BudgetHealthState.warning ||
        budget.healthState == BudgetHealthState.critical;

    Color statusTextColor = AppColors.primary;
    if (isExceeded) {
      statusTextColor = AppColors.danger;
    } else if (isNearLimit) {
      statusTextColor = const Color(0xFFE11D48); // Red-pink "Near your limit" from mockup
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExceeded ? AppColors.danger.withValues(alpha: 0.5) : AppColors.borderLight,
          width: isExceeded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Monthly budget',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                _formatAmount(budget.totalBudget),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal Progress Bar
          BudgetProgress(
            percentage: budget.percentageUsed,
            height: 9,
            overrideColor: isExceeded ? AppColors.danger : AppColors.primary,
          ),
          const SizedBox(height: 14),

          // Spent & Remaining Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatAmount(budget.totalSpent),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isExceeded
                        ? '-${_formatAmount(budget.exceededAmount)}'
                        : _formatAmount(budget.remainingAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isExceeded
                          ? AppColors.danger
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isExceeded || isNearLimit)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    isExceeded
                        ? 'Exceeded by ${_formatAmount(budget.exceededAmount)}'
                        : budget.statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusTextColor,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: onEditBudget,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Edit budget',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

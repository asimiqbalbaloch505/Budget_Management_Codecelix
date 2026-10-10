import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../models/category_budget_model.dart';
import 'budget_progress.dart';

/// Renders an individual category budget row or card
class CategoryBudgetItem extends StatelessWidget {
  final CategoryBudgetModel category;
  final String currencySymbol;
  final bool showDetailedBreakdown;

  const CategoryBudgetItem({
    super.key,
    required this.category,
    this.currencySymbol = 'PKR ',
    this.showDetailedBreakdown = false,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_US');
    return '$currencySymbol${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExceeded = category.healthState == BudgetHealthState.exceeded;
    final isCritical = category.healthState == BudgetHealthState.critical;

    // In Screen 9, Bills at 87% shows text in danger color
    final percentageColor = (isExceeded || isCritical || category.percentageUsed >= 85)
        ? AppColors.danger
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    if (showDetailedBreakdown) {
      // Detailed Card View (Part C requirement)
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExceeded ? AppColors.danger.withValues(alpha: 0.4) : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: category.iconBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    category.iconData,
                    size: 20,
                    color: category.iconForegroundColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.categoryName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Budget: ${_formatAmount(category.limitAmount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${category.percentageUsed.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: percentageColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isExceeded
                          ? 'Exceeded by ${_formatAmount(category.exceededAmount)}'
                          : 'Left: ${_formatAmount(category.remainingAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isExceeded ? AppColors.danger : AppColors.safe,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            BudgetProgress(
              percentage: category.percentageUsed,
              height: 6,
              overrideColor: isExceeded ? AppColors.danger : AppColors.primary,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${_formatAmount(category.spentAmount)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  isExceeded ? 'Limit exceeded' : 'Remaining: ${_formatAmount(category.remainingAmount)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isExceeded ? AppColors.danger : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Clean Minimal Row View (Screen 9 mockup)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.categoryName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '${category.percentageUsed.round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: percentageColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          BudgetProgress(
            percentage: category.percentageUsed,
            height: 6,
            overrideColor: isExceeded ? AppColors.danger : AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// The grouped Category Spending card shown in Screen 9
class CategorySpendingSectionCard extends StatelessWidget {
  final List<CategoryBudgetModel> categories;
  final String currencySymbol;
  final bool isDetailed;
  final VoidCallback? onToggleDetail;

  const CategorySpendingSectionCard({
    super.key,
    required this.categories,
    this.currencySymbol = 'PKR ',
    this.isDetailed = false,
    this.onToggleDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category spending',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              if (onToggleDetail != null)
                GestureDetector(
                  onTap: onToggleDetail,
                  child: Text(
                    isDetailed ? 'Compact' : 'Details',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...categories.map(
            (cat) => CategoryBudgetItem(
              category: cat,
              currencySymbol: currencySymbol,
              showDetailedBreakdown: isDetailed,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/budget_repository.dart';
import 'models/budget_model.dart';
import 'widgets/month_selector.dart';

class EditBudgetScreen extends StatefulWidget {
  final BudgetModel budget;
  final BudgetRepository repository;
  final VoidCallback onBudgetSaved;

  const EditBudgetScreen({
    super.key,
    required this.budget,
    required this.repository,
    required this.onBudgetSaved,
  });

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  late String _selectedMonth;
  late TextEditingController _totalBudgetController;
  final Map<int, TextEditingController> _categoryControllers = {};
  bool _isSaving = false;

  final List<String> _availableMonths = [
    'February 2025',
    'March 2025',
    'April 2025',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.budget.displayMonth;
    _totalBudgetController = TextEditingController(
      text: widget.budget.totalBudget.toStringAsFixed(0),
    );

    for (final cat in widget.budget.categoryBudgets) {
      _categoryControllers[cat.categoryId] = TextEditingController(
        text: cat.limitAmount.toStringAsFixed(0),
      );
    }

    _totalBudgetController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (final c in _categoryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _currentTotalBudget {
    return double.tryParse(_totalBudgetController.text.replaceAll(',', '')) ?? 0.0;
  }

  double get _currentCategoriesSum {
    double sum = 0.0;
    for (final c in _categoryControllers.values) {
      sum += double.tryParse(c.text.replaceAll(',', '')) ?? 0.0;
    }
    return sum;
  }

  bool get _isExceedingTotal => _currentCategoriesSum > _currentTotalBudget;

  String _formatNumber(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_US');
    return formatter.format(amount.round());
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final total = _currentTotalBudget;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid monthly budget limit'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedCategories = widget.budget.categoryBudgets.map((cat) {
        final ctrl = _categoryControllers[cat.categoryId];
        final newLimit = (ctrl != null)
            ? (double.tryParse(ctrl.text.replaceAll(',', '')) ?? cat.limitAmount)
            : cat.limitAmount;
        return cat.copyWith(limitAmount: newLimit);
      }).toList();

      await widget.repository.saveBudget(
        monthYear: _selectedMonth,
        totalBudget: total,
        categoryBudgets: updatedCategories,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monthly budget saved successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
        widget.onBudgetSaved();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save budget: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit monthly budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Selector Dropdown
                    MonthSelector(
                      selectedMonth: _selectedMonth,
                      availableMonths: _availableMonths,
                      onMonthChanged: (m) => setState(() => _selectedMonth = m),
                    ),
                    const SizedBox(height: 12),

                    // Instruction subtext
                    Text(
                      'Plan your spending limits by category.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total Monthly Budget Field
                    Text(
                      'Total monthly budget',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _totalBudgetController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        prefixText: 'PKR ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Budgets Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category budgets',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'Allocated: PKR ${_formatNumber(_currentCategoriesSum)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isExceedingTotal ? AppColors.danger : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category List
                    ...widget.budget.categoryBudgets.map((cat) {
                      final ctrl = _categoryControllers[cat.categoryId];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cat.iconBackgroundColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                cat.iconData,
                                size: 18,
                                color: cat.iconForegroundColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Text(
                                cat.categoryName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  prefixText: 'PKR ',
                                  prefixStyle: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.borderLight),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.borderLight),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    // Helper / warning note (Screen 14)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isExceedingTotal
                            ? AppColors.dangerLight
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isExceedingTotal ? Icons.warning_rounded : Icons.info_outline,
                            size: 16,
                            color: _isExceedingTotal ? AppColors.danger : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isExceedingTotal
                                  ? 'Category totals exceed your monthly budget by PKR ${_formatNumber(_currentCategoriesSum - _currentTotalBudget)}.'
                                  : 'Category totals should not exceed your monthly budget.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isExceedingTotal ? AppColors.danger : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Save Button (Screen 14)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: const Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save budget',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

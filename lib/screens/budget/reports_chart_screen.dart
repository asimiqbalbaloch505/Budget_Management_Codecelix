import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/budget_repository.dart';
import 'models/budget_model.dart';
import 'widgets/month_selector.dart';
import 'widgets/budget_chart.dart';

class ReportsChartScreen extends StatefulWidget {
  final String initialMonth;
  final BudgetRepository repository;

  const ReportsChartScreen({
    super.key,
    required this.initialMonth,
    required this.repository,
  });

  @override
  State<ReportsChartScreen> createState() => _ReportsChartScreenState();
}

class _ReportsChartScreenState extends State<ReportsChartScreen> {
  late String _selectedMonth;
  int _selectedTab = 2; // 0: Daily, 1: Weekly, 2: Monthly
  final List<String> _tabs = ['Daily', 'Weekly', 'Monthly'];

  final List<String> _availableMonths = [
    'February 2025',
    'March 2025',
    'April 2025',
  ];

  BudgetModel? _budget;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final b = await widget.repository.getBudget(_selectedMonth);
      if (mounted) {
        setState(() {
          _budget = b;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_US');
    return 'PKR ${formatter.format(amount.round())}';
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
        title: const Text('Budget & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Selector (Screen 15)
                    MonthSelector(
                      selectedMonth: _selectedMonth,
                      availableMonths: _availableMonths,
                      onMonthChanged: (m) {
                        setState(() => _selectedMonth = m);
                        _fetchData();
                      },
                    ),
                    const SizedBox(height: 14),

                    // Daily / Weekly / Monthly Filter Pills
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: List.generate(_tabs.length, (index) {
                          final isSelected = _selectedTab == index;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF334155) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _tabs[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Income vs. Expense Bar Chart Card (Screen 15)
                    const IncomeVsExpenseBarChart(),
                    const SizedBox(height: 16),

                    // Highest spending category Card (Screen 15)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.catShoppingBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.catShoppingIcon,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Highest spending category',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Shopping',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'PKR 8,250 spent this month',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '24%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bottom Summary Numbers (Screen 15)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            title: 'Total income',
                            amount: _formatAmount(120000.0),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            title: 'Total expenses',
                            amount: _formatAmount(_budget?.totalSpent ?? 35750.0),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            title: 'Net savings',
                            amount: _formatAmount(84250.0),
                            isDark: isDark,
                            amountColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String amount,
    required bool isDark,
    Color? amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: amountColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

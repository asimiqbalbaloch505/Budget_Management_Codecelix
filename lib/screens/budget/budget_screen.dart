import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/budget_repository.dart';
import 'models/budget_model.dart';
import 'widgets/month_selector.dart';
import 'widgets/budget_summary_card.dart';
import 'widgets/category_budget_card.dart';
import 'widgets/budget_alert_card.dart';
import 'widgets/budget_chart.dart';
import 'edit_budget_screen.dart';
import 'reports_chart_screen.dart';

class BudgetScreen extends StatefulWidget {
  final BudgetRepository? repository;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const BudgetScreen({
    super.key,
    this.repository,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late final BudgetRepository _budgetRepo;

  String _selectedMonth = 'March 2025';
  final List<String> _availableMonths = [
    'February 2025',
    'March 2025',
    'April 2025',
  ];

  int _selectedTab = 2; // 0: Daily, 1: Weekly, 2: Monthly
  final List<String> _tabs = ['Daily', 'Weekly', 'Monthly'];

  BudgetModel? _budget;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showDetailedCategories = false;

  @override
  void initState() {
    super.initState();
    _budgetRepo = widget.repository ?? MockBudgetRepository();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _budgetRepo.getBudget(_selectedMonth);
      if (mounted) {
        setState(() {
          _budget = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load budget information. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _onMonthChanged(String newMonth) {
    if (_selectedMonth != newMonth) {
      setState(() {
        _selectedMonth = newMonth;
      });
      _loadBudgetData();
    }
  }

  Future<void> _openEditBudget() async {
    if (_budget == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditBudgetScreen(
          budget: _budget!,
          repository: _budgetRepo,
          onBudgetSaved: () => _loadBudgetData(),
        ),
      ),
    );

    if (updated == true) {
      _loadBudgetData();
    }
  }

  void _openDetailedReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsChartScreen(
          initialMonth: _selectedMonth,
          repository: _budgetRepo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary,
              child: const Text(
                'AS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        title: const Text('Budget & Reports'),
        actions: [
          IconButton(
            tooltip: 'View detailed analytics',
            icon: const Icon(Icons.bar_chart_rounded, size: 22),
            onPressed: _openDetailedReports,
          ),
          if (widget.onToggleTheme != null)
            IconButton(
              tooltip: 'Toggle Theme',
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
              ),
              onPressed: widget.onToggleTheme,
            ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bills are at 87% of your monthly budget'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadBudgetData,
          child: _buildBody(isDark),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_budget == null || _budget!.categoryBudgets.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector (Screen 9 dropdown)
          MonthSelector(
            selectedMonth: _selectedMonth,
            availableMonths: _availableMonths,
            onMonthChanged: _onMonthChanged,
          ),
          const SizedBox(height: 14),

          // Monthly Budget Summary Card
          BudgetSummaryCard(
            budget: _budget!,
            onEditBudget: _openEditBudget,
          ),
          const SizedBox(height: 14),

          // Category Spending Card
          CategorySpendingSectionCard(
            categories: _budget!.categoryBudgets,
            isDetailed: _showDetailedCategories,
            onToggleDetail: () {
              setState(() {
                _showDetailedCategories = !_showDetailedCategories;
              });
            },
          ),
          const SizedBox(height: 10),

          // Budget Alert / Exceeded Banner
          BudgetAlertCard(budget: _budget!),
          const SizedBox(height: 12),

          // Time Period Pill Filter (Daily, Weekly, Monthly)
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
                    onTap: () {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
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
          const SizedBox(height: 14),

          // Spending Trend Visualization
          const BudgetOverviewChart(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 130,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No budget set for this month',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set limits for your categories to start tracking spending against your targets.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openEditBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Set Monthly Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadBudgetData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/formatters.dart';
import '../../models/models.dart';
import '../../providers/transaction_provider.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/category_style.dart';
import '../transactions/transaction_tile.dart';
import 'transaction_history_screen.dart';

/// Home screen — GET /api/dashboard
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransactionProvider>();
    final s = p.summary;
    final cur = p.currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransactionSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: p.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            _MonthSwitcher(provider: p),
            _BalanceCard(summary: s, currency: cur),
            const SizedBox(height: 12),
            _IncomeExpenseRow(summary: s, currency: cur),
            const SizedBox(height: 12),
            _BudgetCard(summary: s, currency: cur),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Spending Summary'),
            _SpendingSummary(items: s.spendingSummary, currency: cur),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Recent Transactions',
              actionLabel: 'See all',
              onAction: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: p,
                  child: const TransactionHistoryScreen(),
                ),
              )),
            ),
            if (s.recentTransactions.isEmpty)
              const _EmptyState(
                icon: Icons.receipt_long_rounded,
                message: 'No transactions this month.\nTap “Add” to log one.',
              )
            else
              for (final t in s.recentTransactions) TransactionTile(tx: t),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.provider});
  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => provider.changeMonth(-1),
          ),
          Text(formatMonthYear(provider.month),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          IconButton(
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: provider.isCurrentMonth ? null : () => provider.changeMonth(1),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary, required this.currency});
  final DashboardSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Balance',
              style: TextStyle(
                  color: scheme.onPrimary.withValues(alpha: 0.85), fontSize: 14)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(summary.totalBalance, currency: currency),
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  const _IncomeExpenseRow({required this.summary, required this.currency});
  final DashboardSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Income',
              value: formatMoney(summary.monthlyIncome, currency: currency),
              icon: Icons.arrow_downward_rounded,
              color: TxColors.income,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Expenses',
              value: formatMoney(summary.monthlyExpenses, currency: currency),
              icon: Icons.arrow_upward_rounded,
              color: TxColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.bodySmall),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.summary, required this.currency});
  final DashboardSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final remaining = summary.remainingBudget;
    final used = summary.budgetUsedFraction;
    final over = remaining != null && remaining < 0;
    final barColor = over
        ? TxColors.expense
        : (used != null && used >= 0.8 ? Colors.orange : TxColors.income);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: remaining == null
            ? Row(children: [
                const Icon(Icons.savings_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('No budget set for this month. Set one in the Budget tab.',
                      style: text.bodyMedium),
                ),
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Remaining Budget',
                          style: text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        over
                            ? '${formatMoney(-remaining, currency: currency)} over'
                            : formatMoney(remaining, currency: currency),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: over ? TxColors.expense : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (used ?? 0).clamp(0.0, 1.0),
                      minHeight: 10,
                      color: barColor,
                      backgroundColor: barColor.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatMoney(summary.monthlyExpenses, currency: currency)} of '
                    '${formatMoney(summary.totalBudget!, currency: currency)} spent'
                    '${used != null ? ' (${(used * 100).round()}%)' : ''}',
                    style: text.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}

class _SpendingSummary extends StatelessWidget {
  const _SpendingSummary({required this.items, required this.currency});
  final List<CategorySpend> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.pie_chart_outline_rounded,
        message: 'Your spending breakdown will appear here.',
      );
    }
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(CategoryStyle.of(i.category).icon,
                          size: 18, color: CategoryStyle.of(i.category).color),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(i.category,
                              style: text.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600))),
                      Text(formatMoney(i.amount, currency: currency),
                          style: text.bodyMedium),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 38,
                        child: Text('${i.percentage}%',
                            textAlign: TextAlign.right, style: text.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: i.percentage / 100,
                      minHeight: 6,
                      color: CategoryStyle.of(i.category).color,
                      backgroundColor:
                          CategoryStyle.of(i.category).color.withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: muted),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted)),
        ],
      ),
    );
  }
}

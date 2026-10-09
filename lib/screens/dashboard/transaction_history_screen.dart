import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/formatters.dart';
import '../../models/models.dart';
import '../../providers/transaction_provider.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_tile.dart';

/// Full history with filters — GET /api/transactions
/// (?type=&categoryId=&startDate=&endDate=)
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  TxType? _type; // null = all
  int? _categoryId;
  DateTimeRange? _range;

  bool get _hasFilters => _type != null || _categoryId != null || _range != null;

  void _clear() => setState(() {
        _type = null;
        _categoryId = null;
        _range = null;
      });

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = DateTimeRange(
            start: DateTime(picked.start.year, picked.start.month, picked.start.day),
            end: DateTime(picked.end.year, picked.end.month, picked.end.day),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransactionProvider>();
    final list = p.query(type: _type, categoryId: _categoryId, range: _range);
    final cats = _type == null ? p.categories : p.categoriesFor(_type!);

    // Group by day (list is already newest-first).
    final groups = <DateTime, List<Transaction>>{};
    for (final t in list) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      groups.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          if (_hasFilters)
            TextButton(onPressed: _clear, child: const Text('Clear')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transaction',
        onPressed: () => showAddTransactionSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // --- filters ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _type == null,
                  onSelected: (_) => setState(() {
                    _type = null;
                    _categoryId = null;
                  }),
                ),
                const SizedBox(width: 8),
                for (final t in TxType.values) ...[
                  ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() {
                      _type = t;
                      _categoryId = null; // categories are type-specific
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text(_range == null
                      ? 'Date range'
                      : '${formatShortDate(_range!.start)} – ${formatShortDate(_range!.end)}'),
                  onPressed: _pickRange,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final c in cats) ...[
                  FilterChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (sel) =>
                        setState(() => _categoryId = sel ? c.id : null),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const Divider(height: 16),

          // --- list ---
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 44,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(height: 10),
                          Text(
                            _hasFilters
                                ? 'No transactions match these filters.'
                                : 'No transactions yet.',
                            textAlign: TextAlign.center,
                          ),
                          if (_hasFilters)
                            TextButton(
                                onPressed: _clear, child: const Text('Clear filters')),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      for (final e in groups.entries) ...[
                        _DayHeader(
                          date: e.key,
                          net: e.value.fold<double>(
                              0,
                              (s, t) =>
                                  s + (t.type == TxType.income ? t.amount : -t.amount)),
                          currency: p.currency,
                        ),
                        for (final t in e.value) TransactionTile(tx: t),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.net, required this.currency});
  final DateTime date;
  final double net;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(formatDay(date),
                style: text.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Text(
            '${net >= 0 ? '+' : '-'}${formatMoney(net.abs(), currency: currency)}',
            style: text.labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

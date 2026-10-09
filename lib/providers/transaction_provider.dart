import 'package:flutter/material.dart';

import '../models/models.dart';

/// State holder the Dashboard / History / Add screens talk to.
///
/// INTEGRATION NOTE (Muhammad Hamza Wasiq): this ships with an in-memory
/// implementation so the UI runs standalone. To go live, keep every public
/// member below and replace the bodies of the methods marked `// SWAP:` with
/// calls to `tx_repo.dart` / `budget_repo.dart`. No UI code needs to change.
class TransactionProvider extends ChangeNotifier {
  TransactionProvider({this.currency = 'PKR'}) {
    _seed();
  }

  final String currency;

  // SWAP: load from SQLite (categories table).
  final List<Category> categories = const [
    Category(id: 1, name: 'Food', type: TxType.expense),
    Category(id: 2, name: 'Bills', type: TxType.expense),
    Category(id: 3, name: 'Transport', type: TxType.expense),
    Category(id: 4, name: 'Shopping', type: TxType.expense),
    Category(id: 5, name: 'Health', type: TxType.expense),
    Category(id: 6, name: 'Entertainment', type: TxType.expense),
    Category(id: 7, name: 'Salary', type: TxType.income),
    Category(id: 8, name: 'Freelance', type: TxType.income),
    Category(id: 9, name: 'Other', type: TxType.income),
  ];

  final List<Transaction> _all = [];
  final double? _totalBudget = 50000; // SWAP: budget_repo (category_id NULL row)
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _nextId = 1000;

  DateTime get month => _month;

  bool get isCurrentMonth {
    final n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  List<Category> categoriesFor(TxType type) =>
      categories.where((c) => c.type == type).toList();

  /// Pull-to-refresh hook. SWAP: re-query the repos, then notify.
  Future<void> refresh() async => notifyListeners();

  void changeMonth(int delta) {
    _month = DateTime(_month.year, _month.month + delta);
    notifyListeners();
  }

  // ---- Dashboard (GET /api/dashboard?month=YYYY-MM) ----------------------

  DashboardSummary get summary {
    // SWAP: replace with SQL aggregation queries.
    final inMonth = _all.where(_sameMonth).toList();
    final income = _sum(inMonth.where((t) => t.type == TxType.income));
    final expenses = _sum(inMonth.where((t) => t.type == TxType.expense));
    final balance = _sum(_all.where((t) => t.type == TxType.income)) -
        _sum(_all.where((t) => t.type == TxType.expense));

    final byCategory = <int, double>{};
    final names = <int, String>{};
    for (final t in inMonth.where((t) => t.type == TxType.expense)) {
      byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
      names[t.categoryId] = t.categoryName;
    }
    final spending = byCategory.entries
        .map((e) => CategorySpend(
              categoryId: e.key,
              category: names[e.key]!,
              amount: e.value,
              percentage:
                  expenses == 0 ? 0 : (e.value / expenses * 100).round(),
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final recent = [...inMonth]..sort(_newestFirst);

    return DashboardSummary(
      totalBalance: balance,
      monthlyIncome: income,
      monthlyExpenses: expenses,
      totalBudget: _totalBudget,
      remainingBudget: _totalBudget == null ? null : _totalBudget - expenses,
      spendingSummary: spending,
      recentTransactions: recent.take(5).toList(),
    );
  }

  // ---- History (GET /api/transactions?type=&categoryId=&startDate=&endDate=)

  List<Transaction> query({
    TxType? type,
    int? categoryId,
    DateTimeRange? range,
  }) {
    // SWAP: tx_repo.query(...) with the same filters.
    final list = _all.where((t) {
      if (type != null && t.type != type) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (range != null) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        if (d.isBefore(range.start) || d.isAfter(range.end)) return false;
      }
      return true;
    }).toList()
      ..sort(_newestFirst);
    return list;
  }

  // ---- Add (POST /api/transactions) --------------------------------------

  Future<void> addTransaction({
    required TxType type,
    required double amount,
    required Category category,
    required DateTime date,
    String? note,
  }) async {
    // SWAP: await txRepo.insert(...); then notifyListeners().
    _all.add(Transaction(
      id: 'tx_${_nextId++}',
      type: type,
      amount: amount,
      categoryId: category.id,
      categoryName: category.name,
      date: DateTime(date.year, date.month, date.day),
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    ));
    notifyListeners();
  }

  // ---- helpers -----------------------------------------------------------

  bool _sameMonth(Transaction t) =>
      t.date.year == _month.year && t.date.month == _month.month;

  double _sum(Iterable<Transaction> list) =>
      list.fold(0.0, (s, t) => s + t.amount);

  int _newestFirst(Transaction a, Transaction b) {
    final c = b.date.compareTo(a.date);
    return c != 0 ? c : b.id.compareTo(a.id);
  }

  void _seed() {
    final n = DateTime.now();
    DateTime d(int daysAgo) => DateTime(n.year, n.month, n.day - daysAgo);
    Category c(int id) => categories.firstWhere((x) => x.id == id);
    void add(String id, TxType t, double a, int cat, int ago, String? note) =>
        _all.add(Transaction(
          id: id,
          type: t,
          amount: a,
          categoryId: cat,
          categoryName: c(cat).name,
          date: d(ago),
          note: note,
        ));

    add('s1', TxType.income, 120000, 7, 0, 'Monthly salary');
    add('s2', TxType.expense, 640, 1, 0, 'Lunch with team');
    add('s3', TxType.expense, 7800, 2, 1, 'Electricity bill');
    add('s4', TxType.expense, 1200, 3, 2, 'Fuel');
    add('s5', TxType.expense, 4800, 4, 3, 'Shoes');
    add('s6', TxType.expense, 2100, 1, 4, 'Groceries');
    add('s7', TxType.income, 15000, 8, 5, 'Logo design gig');
    add('s8', TxType.expense, 900, 6, 6, 'Cinema');
  }
}

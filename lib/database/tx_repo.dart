import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'db_helper.dart';

// ============================================================
// TRANSACTION MODEL
// Matches the `transactions` table in the architecture document.
// ============================================================

class TransactionModel {
  final String id;
  final String userId;
  final int? categoryId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String transactionDate; // 'YYYY-MM-DD'
  final String? note;
  final String createdAt;

  /// Filled by TxRepo from the categories table (not stored in transactions).
  final String? categoryName;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.note,
    this.createdAt = '',
    this.categoryName,
  });

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, {
    String? categoryName,
  }) {
    return TransactionModel(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      categoryId: map['category_id'] == null
          ? null
          : (map['category_id'] as num).toInt(),
      type: map['type'] as String,
      amount: _toDouble(map['amount']),
      transactionDate: map['transaction_date'].toString(),
      note: map['note'] as String?,
      createdAt: (map['created_at'] ?? '').toString(),
      categoryName: categoryName,
    );
  }

  /// Same shape as the API contract's "recentTransactions" items.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': note,
      'amount': amount,
      'type': type,
      'date': transactionDate,
      'category': categoryName,
    };
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

// ============================================================
// TRANSACTION REPOSITORY (Supabase)
// All queries for income and expenses.
//
// Uses DbHelper.client (Shahzad Ali's db_helper.dart) and the
// currently signed-in user. The user must sign in with
// DbHelper.client.auth, otherwise these methods throw StateError.
// Database errors are thrown as PostgrestException.
// ============================================================

class TxRepo {
  static const String table = 'transactions';

  static const String _columns =
      'id, user_id, category_id, type, amount, transaction_date, note, created_at';

  static final RegExp _monthPattern = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

  SupabaseClient get _client => DbHelper.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Please sign in before using transactions.');
    }
    return id;
  }

  // ------------------------------------------------------------
  // INSERT
  // ------------------------------------------------------------

  /// Saves a new income or expense and returns the saved record.
  /// Mirrors POST /api/transactions.
  Future<TransactionModel> insertTransaction({
    required String type,
    required double amount,
    required DateTime date,
    int? categoryId,
    String? note,
  }) async {
    _validateType(type);
    _validateAmount(amount);

    final row = await _client
        .from(table)
        .insert({
          'id': _generateId(),
          'user_id': _userId,
          'category_id': categoryId,
          'type': type,
          'amount': amount,
          'transaction_date': _formatDate(date),
          'note': _cleanNote(note),
        })
        .select(_columns)
        .single();

    final names = await _categoryNames();
    return _toModel(row, names);
  }

  // ------------------------------------------------------------
  // READ
  // ------------------------------------------------------------

  /// Transaction history with optional filters, newest first.
  /// Mirrors GET /api/transactions
  /// (?type=expense&categoryId=1&startDate=...&endDate=...).
  Future<List<TransactionModel>> getTransactions({
    String? type,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    var query = _client.from(table).select(_columns).eq('user_id', _userId);

    if (type != null) {
      _validateType(type);
      query = query.eq('type', type);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (startDate != null) {
      query = query.gte('transaction_date', _formatDate(startDate));
    }
    if (endDate != null) {
      query = query.lte('transaction_date', _formatDate(endDate));
    }

    var ordered = query
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false);

    if (limit != null) {
      final from = offset ?? 0;
      ordered = ordered.range(from, from + limit - 1);
    }

    final rows = await ordered;
    final names = await _categoryNames();
    return rows.map((row) => _toModel(row, names)).toList();
  }

  /// Latest transactions for the dashboard's "recentTransactions" list.
  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) {
    return getTransactions(limit: limit);
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final row = await _client
        .from(table)
        .select(_columns)
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();

    if (row == null) return null;
    final names = await _categoryNames();
    return _toModel(row, names);
  }

  // ------------------------------------------------------------
  // UPDATE / DELETE
  // ------------------------------------------------------------

  /// Returns true if a row was updated.
  Future<bool> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required DateTime date,
    int? categoryId,
    String? note,
  }) async {
    _validateType(type);
    _validateAmount(amount);

    final rows = await _client
        .from(table)
        .update({
          'type': type,
          'amount': amount,
          'transaction_date': _formatDate(date),
          'category_id': categoryId,
          'note': _cleanNote(note),
        })
        .eq('id', id)
        .eq('user_id', _userId)
        .select('id');

    return rows.isNotEmpty;
  }

  /// Returns true if a row was deleted.
  Future<bool> deleteTransaction(String id) async {
    final rows = await _client
        .from(table)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId)
        .select('id');

    return rows.isNotEmpty;
  }

  // ------------------------------------------------------------
  // AGGREGATES (Dashboard, Budget and AI modules)
  // ------------------------------------------------------------

  /// All-time balance: total income minus total expenses.
  /// Used for "totalBalance" on the dashboard.
  Future<double> getTotalBalance() async {
    final rows =
        await _client.from(table).select('type, amount').eq('user_id', _userId);

    double income = 0;
    double expenses = 0;
    for (final row in rows) {
      final amount = _toDouble(row['amount']);
      if (row['type'] == 'income') {
        income += amount;
      } else {
        expenses += amount;
      }
    }
    return income - expenses;
  }

  /// Income and expense totals for one month ([monthYear] = 'YYYY-MM').
  /// Returns {'income': x, 'expenses': y}.
  Future<Map<String, double>> getMonthlyTotals(String monthYear) async {
    final rows = await _monthRows(monthYear, 'type, amount');

    double income = 0;
    double expenses = 0;
    for (final row in rows) {
      final amount = _toDouble(row['amount']);
      if (row['type'] == 'income') {
        income += amount;
      } else {
        expenses += amount;
      }
    }
    return {'income': income, 'expenses': expenses};
  }

  /// Expense breakdown by category for one month, largest first.
  /// Same shape as the API's "spendingSummary":
  /// [{category, amount, percentage}].
  Future<List<Map<String, dynamic>>> getSpendingSummary(
    String monthYear,
  ) async {
    final rows = await _monthRows(monthYear, 'type, amount, category_id');
    final names = await _categoryNames();

    final byName = <String, double>{};
    double total = 0;
    for (final row in rows) {
      if (row['type'] != 'expense') continue;

      final amount = _toDouble(row['amount']);
      final id = row['category_id'] == null
          ? null
          : (row['category_id'] as num).toInt();
      final name = (id == null ? null : names[id]) ?? 'Uncategorized';

      byName[name] = (byName[name] ?? 0) + amount;
      total += amount;
    }

    final entries = byName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((e) {
      return {
        'category': e.key,
        'amount': e.value,
        'percentage': total == 0 ? 0 : (e.value / total * 100).round(),
      };
    }).toList();
  }

  /// Expenses per category id for one month: {categoryId: spent}.
  /// Used by the budget screens for progress bars.
  Future<Map<int, double>> getSpentByCategory(String monthYear) async {
    final rows = await _monthRows(monthYear, 'type, amount, category_id');

    final spent = <int, double>{};
    for (final row in rows) {
      if (row['type'] != 'expense' || row['category_id'] == null) continue;

      final id = (row['category_id'] as num).toInt();
      spent[id] = (spent[id] ?? 0) + _toDouble(row['amount']);
    }
    return spent;
  }

  /// Total spent in one category for one month.
  Future<double> getCategorySpent(int categoryId, String monthYear) async {
    final spent = await getSpentByCategory(monthYear);
    return spent[categoryId] ?? 0;
  }

  /// Compact summary for the AI service and the AI insights screens.
  Future<Map<String, dynamic>> getFinancialSummary(String monthYear) async {
    final totals = await getMonthlyTotals(monthYear);
    final spending = await getSpendingSummary(monthYear);
    final recent = await getRecentTransactions(limit: 10);

    return {
      'month': monthYear,
      'monthlyIncome': totals['income'],
      'monthlyExpenses': totals['expenses'],
      'spendingSummary': spending,
      'recentTransactions': recent.map((t) => t.toJson()).toList(),
    };
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  /// Rows of the current user whose transaction_date is in [monthYear].
  Future<List<Map<String, dynamic>>> _monthRows(
    String monthYear,
    String columns,
  ) async {
    if (!_monthPattern.hasMatch(monthYear)) {
      throw ArgumentError("Month must use the format 'YYYY-MM'.");
    }

    final year = int.parse(monthYear.substring(0, 4));
    final month = int.parse(monthYear.substring(5, 7));
    final nextYear = month == 12 ? year + 1 : year;
    final nextMonth = month == 12 ? 1 : month + 1;

    final start = '$monthYear-01';
    final end = '${nextYear.toString().padLeft(4, '0')}-'
        '${nextMonth.toString().padLeft(2, '0')}-01';

    final rows = await _client
        .from(table)
        .select(columns)
        .eq('user_id', _userId)
        .gte('transaction_date', start)
        .lt('transaction_date', end);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// {categoryId: categoryName} from the categories table.
  Future<Map<int, String>> _categoryNames() async {
    final categories = await DbHelper.getCategories();
    return {
      for (final c in categories) (c['id'] as num).toInt(): c['name'] as String,
    };
  }

  TransactionModel _toModel(Map<String, dynamic> row, Map<int, String> names) {
    final categoryId =
        row['category_id'] == null ? null : (row['category_id'] as num).toInt();
    return TransactionModel.fromMap(
      row,
      categoryName: categoryId == null ? null : names[categoryId],
    );
  }

  void _validateType(String type) {
    if (type != 'income' && type != 'expense') {
      throw ArgumentError("Type must be 'income' or 'expense'.");
    }
  }

  void _validateAmount(double amount) {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
  }

  String? _cleanNote(String? note) {
    if (note == null || note.trim().isEmpty) return null;
    return note.trim();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Random UUID v4, so we don't need an extra package in pubspec.yaml.
  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

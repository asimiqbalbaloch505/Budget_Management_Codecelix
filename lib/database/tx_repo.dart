import 'dart:math';

import 'package:sqflite/sqflite.dart';

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

  /// Filled only by queries that join the categories table.
  final String? categoryName;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.note,
    required this.createdAt,
    this.categoryName,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      transactionDate: map['transaction_date'] as String,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
      categoryName: map['category_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'transaction_date': transactionDate,
      'note': note,
      'created_at': createdAt,
    };
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

// ============================================================
// TRANSACTION REPOSITORY
// All SQLite queries for income and expenses.
// ============================================================

class TxRepo {
  static const String table = 'transactions';

  static final RegExp _monthPattern = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

  /// Uses the database created by db_helper.dart (Shahzad Ali).
  /// Expected API: DbHelper.instance.database -> Future<Database>
  Future<Database> get _db async => DbHelper.instance.database;

  // ------------------------------------------------------------
  // INSERT
  // ------------------------------------------------------------

  /// Saves a new income or expense and returns the saved record.
  /// Mirrors POST /api/transactions.
  Future<TransactionModel> insertTransaction({
    required String userId,
    required String type,
    required double amount,
    required DateTime date,
    int? categoryId,
    String? note,
  }) async {
    _validateType(type);

    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    final tx = TransactionModel(
      id: _generateId(),
      userId: userId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      transactionDate: _formatDate(date),
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    final db = await _db;
    await db.insert(
      table,
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return tx;
  }

  // ------------------------------------------------------------
  // READ
  // ------------------------------------------------------------

  /// Transaction history with optional filters, newest first.
  /// Mirrors GET /api/transactions
  /// (?type=expense&categoryId=1&startDate=...&endDate=...).
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    String? type,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final where = <String>['t.user_id = ?'];
    final args = <Object?>[userId];

    if (type != null) {
      _validateType(type);
      where.add('t.type = ?');
      args.add(type);
    }
    if (categoryId != null) {
      where.add('t.category_id = ?');
      args.add(categoryId);
    }
    if (startDate != null) {
      where.add('t.transaction_date >= ?');
      args.add(_formatDate(startDate));
    }
    if (endDate != null) {
      where.add('t.transaction_date <= ?');
      args.add(_formatDate(endDate));
    }

    final sql = StringBuffer()
      ..write('SELECT t.*, c.name AS category_name ')
      ..write('FROM $table t ')
      ..write('LEFT JOIN categories c ON c.id = t.category_id ')
      ..write('WHERE ${where.join(' AND ')} ')
      ..write('ORDER BY t.transaction_date DESC, t.created_at DESC');

    if (limit != null) {
      sql.write(' LIMIT ?');
      args.add(limit);
      if (offset != null) {
        sql.write(' OFFSET ?');
        args.add(offset);
      }
    }

    final db = await _db;
    final rows = await db.rawQuery(sql.toString(), args);
    return rows.map(TransactionModel.fromMap).toList();
  }

  /// Latest transactions for the dashboard's "recentTransactions" list.
  Future<List<TransactionModel>> getRecentTransactions(
    String userId, {
    int limit = 5,
  }) {
    return getTransactions(userId: userId, limit: limit);
  }

  Future<TransactionModel?> getTransactionById(
    String id,
    String userId,
  ) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT t.*, c.name AS category_name '
      'FROM $table t '
      'LEFT JOIN categories c ON c.id = t.category_id '
      'WHERE t.id = ? AND t.user_id = ? '
      'LIMIT 1',
      [id, userId],
    );

    if (rows.isEmpty) return null;
    return TransactionModel.fromMap(rows.first);
  }

  // ------------------------------------------------------------
  // UPDATE / DELETE
  // ------------------------------------------------------------

  /// Returns true if a row was updated.
  Future<bool> updateTransaction({
    required String id,
    required String userId,
    required String type,
    required double amount,
    required DateTime date,
    int? categoryId,
    String? note,
  }) async {
    _validateType(type);

    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    final db = await _db;
    final count = await db.update(
      table,
      {
        'type': type,
        'amount': amount,
        'transaction_date': _formatDate(date),
        'category_id': categoryId,
        'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    return count > 0;
  }

  /// Returns true if a row was deleted.
  Future<bool> deleteTransaction(String id, String userId) async {
    final db = await _db;
    final count = await db.delete(
      table,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    return count > 0;
  }

  // ------------------------------------------------------------
  // AGGREGATES (Dashboard, Budget and AI modules)
  // ------------------------------------------------------------

  /// All-time balance: total income minus total expenses.
  /// Used for "totalBalance" on the dashboard.
  Future<double> getTotalBalance(String userId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      "SELECT "
      "COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income, "
      "COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expenses "
      "FROM $table WHERE user_id = ?",
      [userId],
    );

    final income = (rows.first['income'] as num).toDouble();
    final expenses = (rows.first['expenses'] as num).toDouble();
    return income - expenses;
  }

  /// Income and expense totals for one month ([monthYear] = 'YYYY-MM').
  /// Returns {'income': x, 'expenses': y}.
  Future<Map<String, double>> getMonthlyTotals(
    String userId,
    String monthYear,
  ) async {
    _validateMonth(monthYear);

    final db = await _db;
    final rows = await db.rawQuery(
      "SELECT "
      "COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income, "
      "COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expenses "
      "FROM $table "
      "WHERE user_id = ? AND strftime('%Y-%m', transaction_date) = ?",
      [userId, monthYear],
    );

    return {
      'income': (rows.first['income'] as num).toDouble(),
      'expenses': (rows.first['expenses'] as num).toDouble(),
    };
  }

  /// Expense breakdown by category for one month, largest first.
  /// Same shape as the API's "spendingSummary":
  /// [{category, amount, percentage}].
  Future<List<Map<String, dynamic>>> getSpendingSummary(
    String userId,
    String monthYear,
  ) async {
    _validateMonth(monthYear);

    final db = await _db;
    final rows = await db.rawQuery(
      "SELECT COALESCE(c.name, 'Uncategorized') AS category, "
      "SUM(t.amount) AS amount "
      "FROM $table t "
      "LEFT JOIN categories c ON c.id = t.category_id "
      "WHERE t.user_id = ? AND t.type = 'expense' "
      "AND strftime('%Y-%m', t.transaction_date) = ? "
      "GROUP BY category "
      "ORDER BY amount DESC",
      [userId, monthYear],
    );

    final total = rows.fold<double>(
      0,
      (sum, row) => sum + (row['amount'] as num).toDouble(),
    );

    return rows.map((row) {
      final amount = (row['amount'] as num).toDouble();
      return {
        'category': row['category'] as String,
        'amount': amount,
        'percentage': total == 0 ? 0 : (amount / total * 100).round(),
      };
    }).toList();
  }

  /// Total spent in one category for one month.
  /// Used by the budget logic (Naeem Khan) for progress bars.
  Future<double> getCategorySpent(
    String userId,
    int categoryId,
    String monthYear,
  ) async {
    _validateMonth(monthYear);

    final db = await _db;
    final rows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) AS total "
      "FROM $table "
      "WHERE user_id = ? AND category_id = ? AND type = 'expense' "
      "AND strftime('%Y-%m', transaction_date) = ?",
      [userId, categoryId, monthYear],
    );

    return (rows.first['total'] as num).toDouble();
  }

  /// Compact summary for the AI service (Sahar's
  /// AiService.generateInsights / askQuestion expect a Map).
  Future<Map<String, dynamic>> getFinancialSummary(
    String userId,
    String monthYear,
  ) async {
    final totals = await getMonthlyTotals(userId, monthYear);
    final spending = await getSpendingSummary(userId, monthYear);
    final recent = await getRecentTransactions(userId, limit: 10);

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

  void _validateType(String type) {
    if (type != 'income' && type != 'expense') {
      throw ArgumentError("Type must be 'income' or 'expense'.");
    }
  }

  void _validateMonth(String monthYear) {
    if (!_monthPattern.hasMatch(monthYear)) {
      throw ArgumentError("Month must use the format 'YYYY-MM'.");
    }
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

    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
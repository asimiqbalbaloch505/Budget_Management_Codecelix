// Shared data models. Field names mirror the DB schema / REST contracts in the
// Technical Architecture Proposal (sections 1 and 2).

enum TxType { income, expense }

extension TxTypeX on TxType {
  String get apiValue => this == TxType.income ? 'income' : 'expense';
  String get label => this == TxType.income ? 'Income' : 'Expense';
  static TxType fromApi(String v) =>
      v == 'income' ? TxType.income : TxType.expense;
}

/// Table: categories
class Category {
  final int id;
  final String? userId; // null = global default
  final String name;
  final TxType type;

  const Category({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
  });
}

/// Table: transactions
class Transaction {
  final String id;
  final TxType type;
  final double amount;
  final int categoryId;
  final String categoryName;
  final DateTime date; // transaction_date (date only)
  final String? note;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.note,
  });

  /// Title shown in lists: the note if present, otherwise the category.
  String get title => (note != null && note!.trim().isNotEmpty)
      ? note!.trim()
      : categoryName;
}

/// One row of `spendingSummary` in GET /api/dashboard.
class CategorySpend {
  final int categoryId;
  final String category;
  final double amount;
  final int percentage;

  const CategorySpend({
    required this.categoryId,
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

/// Shape of `data` in GET /api/dashboard.
class DashboardSummary {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpenses;

  /// null when the user has not set a total budget for the month.
  final double? totalBudget;
  final double? remainingBudget;
  final List<CategorySpend> spendingSummary;
  final List<Transaction> recentTransactions;

  const DashboardSummary({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.totalBudget,
    required this.remainingBudget,
    required this.spendingSummary,
    required this.recentTransactions,
  });

  /// 0..1+ (can exceed 1 when over budget). null if no budget.
  double? get budgetUsedFraction => (totalBudget == null || totalBudget == 0)
      ? null
      : monthlyExpenses / totalBudget!;
}

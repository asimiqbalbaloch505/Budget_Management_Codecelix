import 'category_budget_model.dart';

class BudgetModel {
  final String monthYear;
  final String displayMonth;
  final double totalBudget;
  final double totalSpent;
  final List<CategoryBudgetModel> categoryBudgets;

  const BudgetModel({
    required this.monthYear,
    required this.displayMonth,
    required this.totalBudget,
    required this.totalSpent,
    required this.categoryBudgets,
  });

  double get remainingAmount => (totalBudget - totalSpent).clamp(0.0, double.infinity);
  double get exceededAmount => totalSpent > totalBudget ? (totalSpent - totalBudget) : 0.0;
  bool get isExceeded => totalSpent > totalBudget;

  double get percentageUsed {
    if (totalBudget <= 0) return 0.0;
    return (totalSpent / totalBudget) * 100.0;
  }

  double get progressFraction {
    if (totalBudget <= 0) return 0.0;
    return (totalSpent / totalBudget).clamp(0.0, 1.0);
  }

  BudgetHealthState get healthState {
    final pct = percentageUsed;
    if (pct >= 100.0) return BudgetHealthState.exceeded;
    if (pct >= 90.0) return BudgetHealthState.critical;
    if (pct >= 70.0) return BudgetHealthState.warning;
    return BudgetHealthState.safe;
  }

  String get statusMessage {
    switch (healthState) {
      case BudgetHealthState.safe:
        return 'On track';
      case BudgetHealthState.warning:
        return 'Near your limit';
      case BudgetHealthState.critical:
        return 'Critical: close to limit';
      case BudgetHealthState.exceeded:
        return 'Budget exceeded';
    }
  }

  /// Finds any category exceeding or approaching critical limit
  CategoryBudgetModel? get highestRiskCategory {
    if (categoryBudgets.isEmpty) return null;
    CategoryBudgetModel? highest;
    for (final cat in categoryBudgets) {
      if (highest == null || cat.percentageUsed > highest.percentageUsed) {
        highest = cat;
      }
    }
    return highest;
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categoryBudgets'] as List<dynamic>? ?? [];
    final parsedCats = rawCats
        .map((item) => CategoryBudgetModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final totalLimit = (json['totalBudget'] ?? 0.0).toDouble();
    final totalSpentCalc = (json['totalSpent'] != null)
        ? (json['totalSpent']).toDouble()
        : parsedCats.fold<double>(0.0, (sum, item) => sum + item.spentAmount);

    return BudgetModel(
      monthYear: json['monthYear'] ?? '2026-03',
      displayMonth: json['displayMonth'] ?? 'March 2025',
      totalBudget: totalLimit,
      totalSpent: totalSpentCalc,
      categoryBudgets: parsedCats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthYear': monthYear,
      'displayMonth': displayMonth,
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'categoryBudgets': categoryBudgets.map((c) => c.toJson()).toList(),
    };
  }

  BudgetModel copyWith({
    String? monthYear,
    String? displayMonth,
    double? totalBudget,
    double? totalSpent,
    List<CategoryBudgetModel>? categoryBudgets,
  }) {
    return BudgetModel(
      monthYear: monthYear ?? this.monthYear,
      displayMonth: displayMonth ?? this.displayMonth,
      totalBudget: totalBudget ?? this.totalBudget,
      totalSpent: totalSpent ?? this.totalSpent,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
    );
  }
}

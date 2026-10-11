import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/budget/models/budget_model.dart';
import '../screens/budget/models/category_budget_model.dart';

abstract class BudgetRepository {
  Future<BudgetModel> getBudget(String monthYear);
  Future<bool> saveBudget({
    required String monthYear,
    required double totalBudget,
    required List<CategoryBudgetModel> categoryBudgets,
  });
}

/// Concrete implementation connecting to backend REST API
class HttpBudgetRepository implements BudgetRepository {
  final String baseUrl;
  final String? authToken;
  final http.Client _client;

  HttpBudgetRepository({
    this.baseUrl = 'http://localhost:3000/api',
    this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  @override
  Future<BudgetModel> getBudget(String monthYear) async {
    final uri = Uri.parse('$baseUrl/budgets?monthYear=$monthYear');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return BudgetModel.fromJson(json['data'] ?? json);
    } else {
      throw Exception('Failed to load budget (${response.statusCode}): ${response.body}');
    }
  }

  @override
  Future<bool> saveBudget({
    required String monthYear,
    required double totalBudget,
    required List<CategoryBudgetModel> categoryBudgets,
  }) async {
    final uri = Uri.parse('$baseUrl/budgets');
    final body = jsonEncode({
      'monthYear': monthYear,
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets.map((c) => {
        'categoryId': c.categoryId,
        'limitAmount': c.limitAmount,
      }).toList(),
    });

    final response = await _client.post(uri, headers: _headers, body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    throw Exception('Failed to save budget (${response.statusCode}): ${response.body}');
  }
}

/// Default in-memory / mock repository conforming to approved mockups
class MockBudgetRepository implements BudgetRepository {
  // Pre-seeded budgets indexed by month string
  final Map<String, BudgetModel> _storage = {};

  MockBudgetRepository() {
    _seedInitialData();
  }

  void _seedInitialData() {
    _storage['March 2025'] = const BudgetModel(
      monthYear: '2025-03',
      displayMonth: 'March 2025',
      totalBudget: 50000.0,
      totalSpent: 35750.0,
      categoryBudgets: [
        CategoryBudgetModel(
          categoryId: 1,
          categoryName: 'Food',
          limitAmount: 12000.0,
          spentAmount: 9480.0, // 79%
          iconType: 'food',
        ),
        CategoryBudgetModel(
          categoryId: 2,
          categoryName: 'Transport',
          limitAmount: 6000.0,
          spentAmount: 4260.0, // 71%
          iconType: 'transport',
        ),
        CategoryBudgetModel(
          categoryId: 3,
          categoryName: 'Shopping',
          limitAmount: 8000.0,
          spentAmount: 6240.0, // 78%
          iconType: 'shopping',
        ),
        CategoryBudgetModel(
          categoryId: 4,
          categoryName: 'Bills',
          limitAmount: 10000.0,
          spentAmount: 8700.0, // 87% (near limit alert)
          iconType: 'bills',
        ),
        CategoryBudgetModel(
          categoryId: 5,
          categoryName: 'Health',
          limitAmount: 5000.0,
          spentAmount: 2800.0, // 56%
          iconType: 'health',
        ),
        CategoryBudgetModel(
          categoryId: 6,
          categoryName: 'Education',
          limitAmount: 4000.0,
          spentAmount: 2470.0, // ~62%
          iconType: 'education',
        ),
        CategoryBudgetModel(
          categoryId: 7,
          categoryName: 'Other',
          limitAmount: 5000.0,
          spentAmount: 1800.0, // 36%
          iconType: 'other',
        ),
      ],
    );

    _storage['February 2025'] = const BudgetModel(
      monthYear: '2025-02',
      displayMonth: 'February 2025',
      totalBudget: 48000.0,
      totalSpent: 42100.0,
      categoryBudgets: [
        CategoryBudgetModel(categoryId: 1, categoryName: 'Food', limitAmount: 11000, spentAmount: 9200),
        CategoryBudgetModel(categoryId: 2, categoryName: 'Transport', limitAmount: 6000, spentAmount: 5100),
        CategoryBudgetModel(categoryId: 3, categoryName: 'Shopping', limitAmount: 7000, spentAmount: 7600), // Exceeded!
        CategoryBudgetModel(categoryId: 4, categoryName: 'Bills', limitAmount: 10000, spentAmount: 9800),
        CategoryBudgetModel(categoryId: 5, categoryName: 'Health', limitAmount: 5000, spentAmount: 3400),
        CategoryBudgetModel(categoryId: 6, categoryName: 'Education', limitAmount: 4000, spentAmount: 4000),
        CategoryBudgetModel(categoryId: 7, categoryName: 'Other', limitAmount: 5000, spentAmount: 3000),
      ],
    );

    _storage['April 2025'] = const BudgetModel(
      monthYear: '2025-04',
      displayMonth: 'April 2025',
      totalBudget: 55000.0,
      totalSpent: 59250.0, // Exceeded overall budget by 4,250!
      categoryBudgets: [
        CategoryBudgetModel(categoryId: 1, categoryName: 'Food', limitAmount: 12000, spentAmount: 13250), // Food exceeded!
        CategoryBudgetModel(categoryId: 2, categoryName: 'Transport', limitAmount: 7000, spentAmount: 6800),
        CategoryBudgetModel(categoryId: 3, categoryName: 'Shopping', limitAmount: 10000, spentAmount: 14200), // Shopping exceeded!
        CategoryBudgetModel(categoryId: 4, categoryName: 'Bills', limitAmount: 11000, spentAmount: 10800),
        CategoryBudgetModel(categoryId: 5, categoryName: 'Health', limitAmount: 5000, spentAmount: 4200),
        CategoryBudgetModel(categoryId: 6, categoryName: 'Education', limitAmount: 5000, spentAmount: 5000),
        CategoryBudgetModel(categoryId: 7, categoryName: 'Other', limitAmount: 5000, spentAmount: 5000),
      ],
    );
  }

  @override
  Future<BudgetModel> getBudget(String monthYear) async {
    // Simulate natural mobile network latency
    await Future.delayed(const Duration(milliseconds: 350));

    if (_storage.containsKey(monthYear)) {
      return _storage[monthYear]!;
    }

    // Default template for newly selected months
    return BudgetModel(
      monthYear: monthYear,
      displayMonth: monthYear,
      totalBudget: 50000.0,
      totalSpent: 21500.0,
      categoryBudgets: [
        CategoryBudgetModel(categoryId: 1, categoryName: 'Food', limitAmount: 12000, spentAmount: 6500),
        CategoryBudgetModel(categoryId: 2, categoryName: 'Transport', limitAmount: 6000, spentAmount: 3200),
        CategoryBudgetModel(categoryId: 3, categoryName: 'Shopping', limitAmount: 8000, spentAmount: 4100),
        CategoryBudgetModel(categoryId: 4, categoryName: 'Bills', limitAmount: 10000, spentAmount: 4500),
        CategoryBudgetModel(categoryId: 5, categoryName: 'Health', limitAmount: 5000, spentAmount: 1200),
        CategoryBudgetModel(categoryId: 6, categoryName: 'Education', limitAmount: 4000, spentAmount: 1000),
        CategoryBudgetModel(categoryId: 7, categoryName: 'Other', limitAmount: 5000, spentAmount: 1000),
      ],
    );
  }

  @override
  Future<bool> saveBudget({
    required String monthYear,
    required double totalBudget,
    required List<CategoryBudgetModel> categoryBudgets,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final existing = _storage[monthYear];
    final currentSpent = existing?.totalSpent ?? 0.0;

    _storage[monthYear] = BudgetModel(
      monthYear: monthYear,
      displayMonth: monthYear,
      totalBudget: totalBudget,
      totalSpent: currentSpent,
      categoryBudgets: categoryBudgets,
    );
    return true;
  }
}

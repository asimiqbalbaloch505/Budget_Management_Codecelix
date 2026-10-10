import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

enum BudgetHealthState {
  safe,      // < 70%
  warning,   // 70% - 89%
  critical,  // 90% - 99%
  exceeded,  // >= 100%
}

class CategoryBudgetModel {
  final int categoryId;
  final String categoryName;
  final double limitAmount;
  final double spentAmount;
  final String iconType;

  const CategoryBudgetModel({
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    required this.spentAmount,
    this.iconType = 'other',
  });

  double get remainingAmount => (limitAmount - spentAmount).clamp(0.0, double.infinity);
  double get exceededAmount => spentAmount > limitAmount ? (spentAmount - limitAmount) : 0.0;
  
  double get percentageUsed {
    if (limitAmount <= 0) return 0.0;
    return (spentAmount / limitAmount) * 100.0;
  }

  double get progressFraction {
    if (limitAmount <= 0) return 0.0;
    return (spentAmount / limitAmount).clamp(0.0, 1.0);
  }

  BudgetHealthState get healthState {
    final pct = percentageUsed;
    if (pct >= 100.0) return BudgetHealthState.exceeded;
    if (pct >= 90.0) return BudgetHealthState.critical;
    if (pct >= 70.0) return BudgetHealthState.warning;
    return BudgetHealthState.safe;
  }

  Color get statusColor {
    switch (healthState) {
      case BudgetHealthState.safe:
        return AppColors.safe;
      case BudgetHealthState.warning:
        return AppColors.primary;
      case BudgetHealthState.critical:
        return AppColors.warning;
      case BudgetHealthState.exceeded:
        return AppColors.danger;
    }
  }

  Color get iconBackgroundColor {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return AppColors.catFoodBg;
      case 'transport':
        return AppColors.catTransportBg;
      case 'shopping':
        return AppColors.catShoppingBg;
      case 'bills':
      case 'electricity bill':
        return AppColors.catBillsBg;
      case 'health':
        return AppColors.catHealthBg;
      case 'education':
        return AppColors.catEducationBg;
      default:
        return AppColors.catOtherBg;
    }
  }

  Color get iconForegroundColor {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return AppColors.catFoodIcon;
      case 'transport':
        return AppColors.catTransportIcon;
      case 'shopping':
        return AppColors.catShoppingIcon;
      case 'bills':
      case 'electricity bill':
        return AppColors.catBillsIcon;
      case 'health':
        return AppColors.catHealthIcon;
      case 'education':
        return AppColors.catEducationIcon;
      default:
        return AppColors.catOtherIcon;
    }
  }

  IconData get iconData {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'bills':
      case 'electricity bill':
        return Icons.bolt_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      case 'education':
        return Icons.school_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  factory CategoryBudgetModel.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetModel(
      categoryId: json['categoryId'] is int
          ? json['categoryId']
          : int.tryParse(json['categoryId']?.toString() ?? '0') ?? 0,
      categoryName: json['categoryName'] ?? json['name'] ?? 'General',
      limitAmount: (json['limitAmount'] ?? json['budget'] ?? 0.0).toDouble(),
      spentAmount: (json['spentAmount'] ?? json['spent'] ?? 0.0).toDouble(),
      iconType: json['iconType'] ?? json['categoryName']?.toString().toLowerCase() ?? 'other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'iconType': iconType,
    };
  }

  CategoryBudgetModel copyWith({
    int? categoryId,
    String? categoryName,
    double? limitAmount,
    double? spentAmount,
    String? iconType,
  }) {
    return CategoryBudgetModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      iconType: iconType ?? this.iconType,
    );
  }
}

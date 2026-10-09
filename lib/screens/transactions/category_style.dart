import 'package:flutter/material.dart';

/// Icon + colour for a category name. Unknown/custom categories fall back to
/// a neutral style so user-created categories still render.
class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);

  static CategoryStyle of(String name) {
    switch (name.toLowerCase()) {
      case 'food':
        return const CategoryStyle(Icons.restaurant_rounded, Color(0xFFF59E0B));
      case 'bills':
        return const CategoryStyle(Icons.receipt_long_rounded, Color(0xFF6366F1));
      case 'transport':
        return const CategoryStyle(Icons.directions_car_rounded, Color(0xFF0EA5E9));
      case 'shopping':
        return const CategoryStyle(Icons.shopping_bag_rounded, Color(0xFFEC4899));
      case 'health':
        return const CategoryStyle(Icons.favorite_rounded, Color(0xFFEF4444));
      case 'entertainment':
        return const CategoryStyle(Icons.movie_rounded, Color(0xFF8B5CF6));
      case 'salary':
        return const CategoryStyle(Icons.account_balance_wallet_rounded, Color(0xFF16A34A));
      case 'freelance':
        return const CategoryStyle(Icons.laptop_mac_rounded, Color(0xFF14B8A6));
      default:
        return const CategoryStyle(Icons.category_rounded, Color(0xFF64748B));
    }
  }
}

/// Semantic colours for income / expense. Kept here so the whole core UI
/// stays consistent; swap for `utils/` theme tokens once the lead publishes them.
class TxColors {
  static const income = Color(0xFF16A34A);
  static const expense = Color(0xFFDC2626);
  static Color of(bool isIncome) => isIncome ? income : expense;
}

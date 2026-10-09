// Standalone preview so the Core UI can be run before the lead's main.dart /
// routing lands:   flutter run -t lib/main_preview.dart
// Delete once main.dart wires DashboardScreen and the provider.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/transaction_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() => runApp(const _Preview());

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: MaterialApp(
        title: 'Smart Expense & Budget Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorSchemeSeed: const Color(0xFF4F46E5), useMaterial3: true),
        darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF4F46E5),
            brightness: Brightness.dark,
            useMaterial3: true),
        home: const DashboardScreen(),
      ),
    );
  }
}

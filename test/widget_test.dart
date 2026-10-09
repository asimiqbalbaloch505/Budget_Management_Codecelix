// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:budget_management_codecelix/providers/transaction_provider.dart';
import 'package:budget_management_codecelix/screens/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('dashboard renders its summary', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TransactionProvider(),
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
  });
}

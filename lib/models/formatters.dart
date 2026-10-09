import 'package:intl/intl.dart';

/// Currency formatting driven by users.currency (default 'PKR').
String formatMoney(double value, {String currency = 'PKR'}) {
  final symbol = switch (currency) {
    'PKR' => 'Rs ',
    'INR' => '₹',
    'USD' => '\$',
    'EUR' => '€',
    'GBP' => '£',
    _ => '$currency ',
  };
  final hasFraction = value != value.truncateToDouble();
  return NumberFormat.currency(
          symbol: symbol, decimalDigits: hasFraction ? 2 : 0)
      .format(value);
}

String formatDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEE, d MMM yyyy').format(d);
}

String formatShortDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

String formatMonthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

/// 'YYYY-MM' — the month_year / ?month= format used by the API.
String apiMonth(DateTime d) => DateFormat('yyyy-MM').format(d);

/// 'YYYY-MM-DD' — the date format used by the API.
String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

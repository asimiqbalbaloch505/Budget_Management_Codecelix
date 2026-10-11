import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Interactive dual-line spending trend chart (Screen 9)
class BudgetOverviewChart extends StatelessWidget {
  final List<double> incomeTrend;
  final List<double> expenseTrend;
  final List<String> labels;

  const BudgetOverviewChart({
    super.key,
    this.incomeTrend = const [18, 24, 22, 28, 25, 30, 28],
    this.expenseTrend = const [12, 16, 14, 20, 19, 24, 22],
    this.labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Trend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Row(
                children: [
                  _buildLegendIndicator(AppColors.primary, 'Income'),
                  const SizedBox(width: 12),
                  _buildLegendIndicator(AppColors.danger, 'Expenses'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _SmoothTrendChartPainter(
                incomeValues: incomeTrend,
                expenseValues: expenseTrend,
                line1Color: AppColors.primary,
                line2Color: AppColors.danger,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((label) {
              return Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _SmoothTrendChartPainter extends CustomPainter {
  final List<double> incomeValues;
  final List<double> expenseValues;
  final Color line1Color;
  final Color line2Color;

  _SmoothTrendChartPainter({
    required this.incomeValues,
    required this.expenseValues,
    required this.line1Color,
    required this.line2Color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (incomeValues.isEmpty || expenseValues.isEmpty) return;

    final paint1 = Paint()
      ..color = line1Color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..color = line2Color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxVal = 35.0;
    final minVal = 5.0;

    Path createSmoothPath(List<double> values) {
      final path = Path();
      final stepX = size.width / (values.length - 1);

      for (int i = 0; i < values.length; i++) {
        final normY = (values[i] - minVal) / (maxVal - minVal);
        final x = i * stepX;
        final y = size.height - (normY * size.height);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevNormY = (values[i - 1] - minVal) / (maxVal - minVal);
          final prevX = (i - 1) * stepX;
          final prevY = size.height - (prevNormY * size.height);

          final cx1 = prevX + (stepX / 2);
          final cy1 = prevY;
          final cx2 = prevX + (stepX / 2);
          final cy2 = y;

          path.cubicTo(cx1, cy1, cx2, cy2, x, y);
        }
      }
      return path;
    }

    canvas.drawPath(createSmoothPath(incomeValues), paint1);
    canvas.drawPath(createSmoothPath(expenseValues), paint2);
  }

  @override
  bool shouldRepaint(covariant _SmoothTrendChartPainter oldDelegate) => true;
}

/// Income vs. Expense Bar Chart (Screen 15)
class IncomeVsExpenseBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const IncomeVsExpenseBarChart({
    super.key,
    this.weeklyData = const [
      {'label': 'Week 1', 'income': 28000.0, 'expense': 9200.0},
      {'label': 'Week 2', 'income': 30000.0, 'expense': 7500.0},
      {'label': 'Week 3', 'income': 31000.0, 'expense': 10500.0},
      {'label': 'Week 4', 'income': 31000.0, 'expense': 8550.0},
    ],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maxVal = 35000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income vs. expense',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Row(
                children: [
                  _buildDot(AppColors.primary, 'Income'),
                  const SizedBox(width: 12),
                  _buildDot(AppColors.danger, 'Expenses'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y-Axis Labels
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildYLabel('₹30k'),
                  const SizedBox(height: 24),
                  _buildYLabel('₹20k'),
                  const SizedBox(height: 24),
                  _buildYLabel('₹10k'),
                  const SizedBox(height: 24),
                  _buildYLabel('₹0'),
                ],
              ),
              const SizedBox(width: 12),
              // Bars Group
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: weeklyData.map((data) {
                    final incomeHeight =
                        ((data['income'] as double) / maxVal) * 120.0;
                    final expenseHeight =
                        ((data['expense'] as double) / maxVal) * 120.0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Income bar (Teal)
                            Container(
                              width: 14,
                              height: incomeHeight,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Expense bar (Coral)
                            Container(
                              width: 14,
                              height: expenseHeight,
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.textMutedLight,
      ),
    );
  }

  Widget _buildDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

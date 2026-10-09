import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/formatters.dart';
import '../../models/models.dart';
import '../../providers/transaction_provider.dart';
import 'category_style.dart';

/// A single transaction row, used by the Dashboard (recent) and History.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx, this.showDate = false});

  final Transaction tx;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<TransactionProvider>().currency;
    final style = CategoryStyle.of(tx.categoryName);
    final isIncome = tx.type == TxType.income;
    final text = Theme.of(context).textTheme;
    final subtitle = showDate
        ? '${tx.categoryName} • ${formatShortDate(tx.date)}'
        : tx.categoryName;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: style.color.withValues(alpha: 0.14),
        child: Icon(style.icon, color: style.color, size: 22),
      ),
      title: Text(tx.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: text.bodySmall),
      trailing: Text(
        '${isIncome ? '+' : '-'}${formatMoney(tx.amount, currency: currency)}',
        style: text.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: TxColors.of(isIncome),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/formatters.dart';
import '../../models/models.dart';
import '../../providers/transaction_provider.dart';
import 'category_style.dart';

/// Opens the Add Income / Expense modal bottom sheet.
/// Returns true if a transaction was saved.
Future<bool?> showAddTransactionSheet(
  BuildContext context, {
  TxType initialType = TxType.expense,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider<TransactionProvider>.value(
      // Re-expose the provider: sheets are built on the root navigator.
      value: context.read<TransactionProvider>(),
      child: AddTransactionSheet(initialType: initialType),
    ),
  );
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, this.initialType = TxType.expense});
  final TxType initialType;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late TxType _type = widget.initialType;
  Category? _category;
  DateTime _date = DateTime.now();
  bool _categoryError = false;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _categoryError = _category == null);
    if (!valid || _category == null) return;

    setState(() => _saving = true);
    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await provider.addTransaction(
        type: _type,
        amount: double.parse(_amountCtrl.text.trim()),
        category: _category!,
        date: _date,
        note: _noteCtrl.text,
      );
      nav.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaction added successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final cats = provider.categoriesFor(_type);
    final isIncome = _type == TxType.income;
    final accent = TxColors.of(isIncome);
    final text = Theme.of(context).textTheme;

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isIncome ? 'Add Income' : 'Add Expense',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TxType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: TxType.expense, label: Text('Expense')),
                    ButtonSegment(value: TxType.income, label: Text('Income')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() {
                    _type = s.first;
                    _category = null; // categories differ per type
                    _categoryError = false;
                  }),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,10}\.?\d{0,2}')),
                ],
                style: text.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700, color: accent),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${provider.currency}  ',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null) return 'Enter an amount';
                  if (n <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text('Category', style: text.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cats)
                    ChoiceChip(
                      avatar: Icon(CategoryStyle.of(c.name).icon,
                          size: 18, color: CategoryStyle.of(c.name).color),
                      label: Text(c.name),
                      selected: _category?.id == c.id,
                      onSelected: (_) => setState(() {
                        _category = c;
                        _categoryError = false;
                      }),
                    ),
                ],
              ),
              if (_categoryError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Please choose a category',
                      style: text.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                  ),
                  child: Text(formatDay(_date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Text(isIncome ? 'Save Income' : 'Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

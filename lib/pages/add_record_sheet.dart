import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ledger_record.dart';

/// 「记一笔」底部表单。
class AddRecordSheet extends StatefulWidget {
  const AddRecordSheet({super.key});

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  RecordType _type = RecordType.expense;
  String _category = Categories.expense.first;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<String> get _categories =>
      _type == RecordType.expense ? Categories.expense : Categories.income;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _switchType(RecordType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _category = _categories.first;
    });
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入大于 0 的金额')),
      );
      return;
    }
    Navigator.of(context).pop(
      LedgerRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: _type,
        amount: amount,
        category: _category,
        note: _noteController.text.trim(),
        date: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('记一笔', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<RecordType>(
            segments: const [
              ButtonSegment(
                value: RecordType.expense,
                label: Text('支出'),
                icon: Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: RecordType.income,
                label: Text('收入'),
                icon: Icon(Icons.add_circle_outline),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => _switchType(s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: '金额（元）',
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('分类', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map(
                  (c) => ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}

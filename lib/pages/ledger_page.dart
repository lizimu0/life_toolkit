import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ledger_record.dart';
import '../services/storage_service.dart';
import '../widgets/trend_chart.dart';
import 'add_record_sheet.dart';

/// 记账主页面（支付宝风格：蓝色主题 + 白色卡片）。
class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  static const Color _blue = Color(0xFF1677FF);

  final List<LedgerRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await StorageService.loadRecords();
    if (!mounted) return;
    setState(() {
      _records
        ..clear()
        ..addAll(records);
      _loading = false;
    });
  }

  void _persist() {
    StorageService.saveRecords(_records);
  }

  Future<void> _openAddSheet() async {
    final record = await showModalBottomSheet<LedgerRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddRecordSheet(),
    );
    if (record == null) return;
    setState(() => _records
      ..add(record)
      ..sort((a, b) => b.date.compareTo(a.date)));
    _persist();
  }

  void _delete(LedgerRecord record) {
    setState(() => _records.remove(record));
    _persist();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除该记录')),
    );
  }

  /// 本月记录。
  List<LedgerRecord> get _monthRecords {
    final now = DateTime.now();
    return _records
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .toList();
  }

  /// 近 6 个月每月支出汇总（旧→新）。
  List<MonthPoint> get _trendPoints {
    final now = DateTime.now();
    final points = <MonthPoint>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final sum = _records
          .where((r) =>
              r.type == RecordType.expense &&
              r.date.year == m.year &&
              r.date.month == m.month)
          .fold<double>(0, (s, r) => s + r.amount);
      points.add(MonthPoint('${m.month}月', sum));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final month = _monthRecords;
    final expense = month
        .where((r) => r.type == RecordType.expense)
        .fold<double>(0, (sum, r) => sum + r.amount);
    final income = month
        .where((r) => r.type == RecordType.income)
        .fold<double>(0, (sum, r) => sum + r.amount);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note),
        label: const Text('记一笔'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                children: [
                  _buildHeaderCard(expense, income),
                  const SizedBox(height: 12),
                  if (expense > 0) ...[
                    _buildCategoryCard(month),
                    const SizedBox(height: 12),
                  ],
                  _buildChartCard(),
                  const SizedBox(height: 12),
                  _buildRecordList(),
                ],
              ),
      ),
    );
  }

  /// 蓝色渐变头部：月份 + 支出/收入/结余。
  Widget _buildHeaderCard(double expense, double income) {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1677FF), Color(0xFF4E9BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                '${now.year}年${now.month}月',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderItem('支出', expense),
              _buildHeaderItem('收入', income),
              _buildHeaderItem('结余', income - expense),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String label, double value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${value.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 本月支出分类卡片。
  Widget _buildCategoryCard(List<LedgerRecord> monthRecords) {
    final byCategory = <String, double>{};
    double total = 0;
    for (final r in monthRecords) {
      if (r.type != RecordType.expense) continue;
      byCategory[r.category] = (byCategory[r.category] ?? 0) + r.amount;
      total += r.amount;
    }
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('本月支出分类'),
          const SizedBox(height: 14),
          ...entries.map((e) {
            final ratio = total == 0 ? 0.0 : e.value / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF0F2F5),
                        color: _blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 116,
                    child: Text(
                      '¥${e.value.toStringAsFixed(2)}'
                      '（${(ratio * 100).toStringAsFixed(0)}%）',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return _card(child: TrendChart(points: _trendPoints));
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildRecordList() {
    if (_records.isEmpty) {
      return _card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long,
                size: 48,
                color: Color(0xFFDDDDDD),
              ),
              const SizedBox(height: 12),
              const Text(
                '还没有记账，点右下角「记一笔」开始吧',
                style: TextStyle(color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
      );
    }

    // 按日期分组。
    final groups = <String, List<LedgerRecord>>{};
    for (final r in _records) {
      final key = DateFormat('yyyy-MM-dd').format(r.date);
      groups.putIfAbsent(key, () => []).add(r);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in keys) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
            child: Text(
              _formatDayHeader(key),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _blue,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _buildGroupRows(groups[key]!),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  List<Widget> _buildGroupRows(List<LedgerRecord> records) {
    final children = <Widget>[];
    for (var i = 0; i < records.length; i++) {
      children.add(_buildRecordTile(records[i]));
      if (i < records.length - 1) {
        children.add(
          const Divider(height: 1, indent: 52, color: Color(0xFFF0F0F0)),
        );
      }
    }
    return children;
  }

  String _formatDayHeader(String key) {
    final date = DateTime.parse(key);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;
    final weekday = const [
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '周日',
    ][date.weekday - 1];
    if (diff == 0) return '今天 · $weekday';
    if (diff == 1) return '昨天 · $weekday';
    return '${date.month}月${date.day}日 · $weekday';
  }

  Widget _buildRecordTile(LedgerRecord r) {
    final isExpense = r.type == RecordType.expense;
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除记录'),
            content: const Text('确定删除这条记账记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => _delete(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isExpense
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                color: isExpense
                    ? const Color(0xFFFF4D4F)
                    : const Color(0xFF00B578),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.category,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                    ),
                  ),
                  if (r.note.isNotEmpty)
                    Text(
                      r.note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}¥${r.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isExpense
                    ? const Color(0xFFFF4D4F)
                    : const Color(0xFF00B578),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

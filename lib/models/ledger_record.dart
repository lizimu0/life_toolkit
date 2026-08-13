/// 记账类型：支出或收入。
enum RecordType { expense, income }

/// 单条记账记录。
class LedgerRecord {
  LedgerRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
  });

  final String id;
  final RecordType type;
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory LedgerRecord.fromJson(Map<String, dynamic> json) => LedgerRecord(
        id: json['id'] as String,
        type: RecordType.values[json['type'] as int],
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        note: json['note'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
      );
}

/// 记账分类常量。
class Categories {
  static const List<String> expense = [
    '餐饮',
    '交通',
    '购物',
    '居家',
    '娱乐',
    '医疗',
    '学习',
    '其他',
  ];

  static const List<String> income = [
    '工资',
    '奖金',
    '理财',
    '红包',
    '其他',
  ];
}

/// 待办事项数据模型。
class TodoItem {
  TodoItem({
    required this.id,
    required this.title,
    this.done = false,
    required this.createdAt,
    this.dueDate,
  });

  final String id;
  String title;
  bool done;
  final DateTime createdAt;

  /// 提醒时间（可空，空表示无提醒）。
  DateTime? dueDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'] as String,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
      );
}

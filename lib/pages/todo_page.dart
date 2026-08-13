import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/todo_item.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// 待办清单筛选方式。
enum TodoFilter { all, active, done }

/// 待办清单页面（支付宝风格：蓝色主题 + 白色卡片）。
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  static const Color _blue = Color(0xFF1677FF);

  final List<TodoItem> _todos = [];
  final TextEditingController _inputController = TextEditingController();
  TodoFilter _filter = TodoFilter.all;
  bool _loading = true;

  /// 新任务的待选提醒时间。
  DateTime? _pickedReminder;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final todos = await StorageService.loadTodos();
    if (!mounted) return;
    setState(() {
      _todos
        ..clear()
        ..addAll(todos);
      _loading = false;
    });
  }

  void _persist() {
    StorageService.saveTodos(_todos);
  }

  void _addTodo() {
    final title = _inputController.text.trim();
    if (title.isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final item = TodoItem(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      dueDate: _pickedReminder,
    );
    setState(() {
      _todos.insert(0, item);
      _pickedReminder = null;
    });
    _inputController.clear();
    _persist();
    if (item.dueDate != null) {
      NotificationService.scheduleTodoReminder(
        int.parse(id),
        title,
        item.dueDate!,
      );
    }
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _pickedReminder?.isAfter(now) == true
          ? _pickedReminder!
          : now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _pickedReminder ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return;
    setState(() {
      _pickedReminder = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _toggleDone(TodoItem item, bool? value) {
    setState(() => item.done = value ?? false);
    _persist();
    // 完成任务后取消对应提醒
    if (item.done && item.dueDate != null) {
      NotificationService.cancel(int.parse(item.id));
    }
  }

  void _delete(TodoItem item) {
    setState(() => _todos.remove(item));
    _persist();
    if (item.dueDate != null) {
      NotificationService.cancel(int.parse(item.id));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除「${item.title}」'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            setState(() => _todos.insert(0, item));
            _persist();
          },
        ),
      ),
    );
  }

  List<TodoItem> get _filtered {
    switch (_filter) {
      case TodoFilter.active:
        return _todos.where((t) => !t.done).toList();
      case TodoFilter.done:
        return _todos.where((t) => t.done).toList();
      case TodoFilter.all:
        return List.of(_todos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _todos.where((t) => !t.done).length;
    final items = _filtered;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(remaining),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      children: [
                        _buildInputCard(),
                        const SizedBox(height: 12),
                        _buildFilterTabs(),
                        const SizedBox(height: 12),
                        if (items.isEmpty) _buildEmpty() else _buildListCard(items),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 蓝色渐变头部卡片。
  Widget _buildHeader(int remaining) {
    final done = _todos.where((t) => t.done).length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
              const Icon(Icons.checklist_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              const Text(
                '待办清单',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _todos.isEmpty
                ? '暂无任务，在下方添加一条吧'
                : '还剩 $remaining 项未完成 · 已完成 $done 项',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 输入卡片：文本框 + 提醒设置 + 添加按钮。
  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: '添加新任务…',
                    hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTodo(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _blue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 22),
                  padding: EdgeInsets.zero,
                  onPressed: _addTodo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_pickedReminder != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        size: 14,
                        color: _blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('M月d日 HH:mm').format(_pickedReminder!),
                        style: const TextStyle(fontSize: 12, color: _blue),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFF999999)),
                  tooltip: '取消提醒',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _pickedReminder = null),
                ),
              ] else
                TextButton.icon(
                  onPressed: _pickReminder,
                  icon: const Icon(Icons.notifications_none, size: 16),
                  label: const Text('设置提醒', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: _blue,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 支付宝式文字标签页。
  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('全部', TodoFilter.all),
          _buildTab('未完成', TodoFilter.active),
          _buildTab('已完成', TodoFilter.done),
        ],
      ),
    );
  }

  Widget _buildTab(String label, TodoFilter value) {
    final selected = _filter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? _blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _blue : const Color(0xFF666666),
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// 列表卡片：白色圆角卡片内的紧凑行列表。
  Widget _buildListCard(List<TodoItem> items) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(_buildRow(items[i]));
      if (i < items.length - 1) {
        children.add(
          const Divider(height: 1, indent: 52, color: Color(0xFFF0F0F0)),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(TodoItem item) {
    final overdue = !item.done &&
        item.dueDate != null &&
        item.dueDate!.isBefore(DateTime.now());
    return Dismissible(
      key: ValueKey(item.id),
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
      onDismissed: (_) => _delete(item),
      child: InkWell(
        onTap: () => _toggleDone(item, !item.done),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                item.done
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: item.done
                    ? const Color(0xFF00B578)
                    : const Color(0xFFCCCCCC),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        decoration:
                            item.done ? TextDecoration.lineThrough : null,
                        color: item.done
                            ? const Color(0xFF999999)
                            : const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.dueDate != null) ...[
                          Icon(
                            Icons.notifications_none,
                            size: 12,
                            color: overdue
                                ? Colors.red
                                : const Color(0xFF999999),
                          ),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          item.dueDate != null
                              ? (overdue ? '已到期 ' : '提醒 ') +
                                  DateFormat('M月d日 HH:mm')
                                      .format(item.dueDate!)
                              : '${item.createdAt.month}月${item.createdAt.day}日创建',
                          style: TextStyle(
                            fontSize: 12,
                            color: overdue
                                ? Colors.red
                                : const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final message = switch (_filter) {
      TodoFilter.active => '太棒了，没有待办事项！',
      TodoFilter.done => '还没有完成过任务，加油！',
      TodoFilter.all => '暂无任务，在上方添加一条吧',
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.task_alt, size: 48, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF999999))),
        ],
      ),
    );
  }
}

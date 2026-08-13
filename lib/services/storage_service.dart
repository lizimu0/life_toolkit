import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ledger_record.dart';
import '../models/todo_item.dart';

/// 基于 shared_preferences 的本地持久化服务。
class StorageService {
  static const String _todosKey = 'todo_items';
  static const String _recordsKey = 'ledger_records';

  static Future<List<TodoItem>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_todosKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveTodos(List<TodoItem> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(todos.map((e) => e.toJson()).toList());
    await prefs.setString(_todosKey, raw);
  }

  static Future<List<LedgerRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => LedgerRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveRecords(List<LedgerRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(_recordsKey, raw);
  }
}

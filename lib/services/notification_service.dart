import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 本地通知服务：负责待办提醒的调度与取消。
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// 通知 ID 必须落在 32 位有符号整数范围内（zonedSchedule 会校验并抛出
  /// ArgumentError），因此用 FNV-1a 将待办的字符串 ID 映射为稳定的 31 位
  /// 整数：同一待办在调度与取消时得到同一 ID，且持久化后重启不变。
  static int notificationId(String itemId) {
    var hash = 0x811c9dc5;
    for (final unit in itemId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      try {
        // 跟随设备时区;获取失败(平台不支持/IANA 名缺失)时回退北京时间
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (e) {
        debugPrint('NotificationService: 获取设备时区失败,回退 Asia/Shanghai: $e');
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
        } catch (e2) {
          debugPrint('NotificationService: 回退时区也失败: $e2');
        }
      }
      const androidSettings =
          AndroidInitializationSettings('mipmap_ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidSettings),
      );
      // Android 13+ 需要运行时申请通知权限
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (e) {
      // 初始化失败不影响应用主体功能，仅提醒不可用
      debugPrint('NotificationService: 初始化失败,提醒功能不可用: $e');
    }
  }

  /// 预约一条待办提醒；时间已过则忽略。
  static Future<void> scheduleTodoReminder(
    int id,
    String title,
    DateTime due,
  ) async {
    if (!_initialized || due.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
      id,
      '待办提醒',
      '时间到了：$title',
      tz.TZDateTime.from(due, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminder',
          '待办提醒',
          channelDescription: '待办事项到期提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // 调度失败不阻断用户操作，但必须留痕，避免提醒静默失效
      debugPrint('NotificationService: 调度提醒失败(id=$id, title=$title): $e');
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('NotificationService: 取消提醒失败(id=$id): $e');
    }
  }
}

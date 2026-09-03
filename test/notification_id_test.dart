import 'package:flutter_test/flutter_test.dart';
import 'package:life_toolkit/services/notification_service.dart';

void main() {
  group('NotificationService.notificationId', () {
    test('返回值落在 32 位有符号整数范围内(zonedSchedule 的硬性要求)', () {
      // microsecondsSinceEpoch 生成的待办 ID 是 16 位数字字符串,此前直接
      // int.parse 后必然超出 32 位导致 ArgumentError 被静默吞掉。
      final id = NotificationService.notificationId(
        DateTime.now().microsecondsSinceEpoch.toString(),
      );
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      expect(id, greaterThanOrEqualTo(0));
    });

    test('同一待办 ID 稳定映射(调度与取消必须得到同一通知 ID)', () {
      const itemId = '1789123456789123';
      expect(NotificationService.notificationId(itemId),
          NotificationService.notificationId(itemId));
    });

    test('不同待办 ID 的哈希分布无聚集', () {
      final ids = List.generate(
        1000,
        (i) => NotificationService.notificationId(
            (1789000000000000 + i).toString()),
      );
      expect(ids.toSet().length, greaterThan(900));
    });
  });
}

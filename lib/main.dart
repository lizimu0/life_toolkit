import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/home_page.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LifeToolkitApp());
  // 通知服务异步初始化，不阻塞界面启动，避免卡启动画面
  NotificationService.init();
}

/// 生活助手：待办清单 + 记账。
class LifeToolkitApp extends StatelessWidget {
  const LifeToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '生活助手',
      debugShowCheckedModeBanner: false,
      // 系统组件(日期/时间选择器等)跟随中文
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      locale: const Locale('zh'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1677FF),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      home: const HomePage(),
    );
  }
}

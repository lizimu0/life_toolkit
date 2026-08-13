# 生活助手（life_toolkit）

一款用 Flutter 开发的手机工具应用，集成**待办清单**和**记账**两大功能，支付宝风格 UI。

## 功能清单

### 待办清单
- 添加、完成（勾选）、删除任务（左滑删除，支持撤销）
- 筛选：全部 / 未完成 / 已完成
- **提醒功能**：添加任务时可设置提醒时间，到点推送通知；完成或删除任务自动取消提醒

### 记账
- 记一笔：支出/收入、金额、分类（餐饮/交通/工资等）、备注
- 本月统计：支出 / 收入 / 结余
- 本月支出分类占比（进度条）
- **近 6 个月支出趋势柱状图**（CustomPaint 自绘，无第三方图表依赖）
- 流水按日期分组（今天/昨天/日期+星期），左滑删除（二次确认）

### 其他
- 数据本地持久化（shared_preferences），卸载前不丢失
- 自定义应用图标与应用名「生活助手」

## 项目结构

```
├── lib/
│   ├── main.dart                     # 应用入口
│   ├── models/                       # 数据模型
│   │   ├── todo_item.dart
│   │   └── ledger_record.dart
│   ├── services/                     # 服务层
│   │   ├── storage_service.dart      # 本地持久化
│   │   └── notification_service.dart # 本地通知
│   ├── pages/                        # 页面
│   │   ├── home_page.dart            # 底部导航框架
│   │   ├── todo_page.dart
│   │   ├── ledger_page.dart
│   │   └── add_record_sheet.dart
│   └── widgets/
│       └── trend_chart.dart          # 自绘趋势图
├── android/                          # Android 平台目录
├── assets/                           # 应用图标源图
└── pubspec.yaml                      # 依赖配置
```

## 环境要求

- Flutter SDK（stable 通道）
- Android SDK（API 34+，含 cmdline-tools、platform-tools）
- 国内网络建议配置 Flutter 镜像：
  - `PUB_HOSTED_URL=https://pub.flutter-io.cn`
  - `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`

## 常用命令

在项目根目录执行：

```bash
# 安装依赖
flutter pub get

# 查看已连接设备
flutter devices

# 调试运行（<设备ID> 用 flutter devices 查到的 ID 替换）
flutter run -d <设备ID>

# 正式运行（AOT 编译，流畅）
flutter run --release -d <设备ID>

# 打包 APK（仅 arm64，适配所有现代手机）
flutter build apk --release --target-platform android-arm64
```

产物位于 `build/app/outputs/flutter-apk/app-release.apk`

### 更换应用图标

替换 `assets/icon.jpg` 后执行：

```bash
dart run flutter_launcher_icons
```

## 注意事项（踩坑记录）

1. **项目路径必须为纯英文**：Android Gradle 插件会拒绝包含中文等非 ASCII 字符的路径。若本仓库位于中文目录下，请先复制到纯英文路径再编译。
2. **项目与 Pub 缓存避免跨盘符**：Kotlin 增量编译的相对路径缓存在跨盘符时会报 `different roots` 错误。解决：`PUB_CACHE` 指向与项目同盘，或在 `android/gradle.properties` 中设置 `kotlin.incremental=false`（本项目已配置）。
3. **国内网络构建**：`android/` 目录已内置 Gradle 分发镜像（腾讯云）与 Maven 仓库镜像（阿里云），无需额外配置。
4. **iOS 打包**：需在 macOS + Xcode 环境执行 `flutter create --platforms ios .` 补充 iOS 目录后编译，Windows 无法构建 iOS 版。

## 运行中的快捷键（flutter run 会话内）

| 按键 | 作用 |
|------|------|
| `r` | 热重载（改代码后秒刷新） |
| `R` | 热重启 |
| `q` | 退出（应用保留在手机上） |

import 'package:flutter/material.dart';                            // 导入 Flutter 核心库
import 'package:hive/hive.dart';                                   // 导入 Hive 本地数据库库，用于数据持久化存储
import 'package:path_provider/path_provider.dart';                 // 导入 path_provider 库，用于获取应用支持的目录路径
import 'package:window_manager/window_manager.dart';               // 导入 window_manager 库，用于桌面窗口管理（Windows、Linux、macOS）
import 'package:flutter_localizations/flutter_localizations.dart'; // 导入 Flutter 国际化支持
import 'dart:io';                                                  // 导入 Dart I/O 库，用于文件系统操作
import 'package:lite_view/screens/pdf_list_screen.dart';           // 导入 PDF 列表页面
import 'l10n/app_localizations.dart';                              // 导入应用本地化配置

/// 应用程序入口函数
/// 初始化 Flutter 绑定、配置应用数据存储路径、初始化 Hive 数据库，并启动应用
void main() async {
  /// 确保 Flutter 绑定已初始化，这是使用异步函数前的必要步骤
  WidgetsFlutterBinding.ensureInitialized();

  /// 根据不同平台获取应用数据存储路径
  Directory path;

  if (Platform.isAndroid) {
    /// Android 平台：获取外部存储目录（如果可用），否则使用应用支持目录
    path = await getExternalStorageDirectory() ?? await getApplicationSupportDirectory();
  } else {
    /// 其他平台（Windows、Linux、macOS）：使用应用支持目录
    path = await getApplicationSupportDirectory();
    print(path.path);
    /// 初始化窗口管理器（桌面平台需要）
    await windowManager.ensureInitialized();
    windowManager.setMinimumSize(Size(350, 350));
  }

  /// 初始化 Hive 本地数据库，指定存储路径
  Hive.init(path.path);

  /// 启动应用程序
  runApp(const MainApp());
}

/// 主应用组件
/// 配置应用的主题、国际化支持和初始页面
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // windowManager.setTitle('轻阅屏');
    return MaterialApp(
      /// 配置本地化代理，支持多语言切换
      localizationsDelegates: const [
        /// 自定义应用本地化代理
        AppLocalizations.delegate,
        /// Material Design 组件的本地化代理
        GlobalMaterialLocalizations.delegate,
        /// Flutter 核心组件的本地化代理
        GlobalWidgetsLocalizations.delegate,
        /// Cupertino (iOS 风格) 组件的本地化代理
        GlobalCupertinoLocalizations.delegate,
      ],
      /// 支持的语言环境列表
      supportedLocales: const [
        /// 简体中文（中国）
        Locale('zh', 'CN'),
        /// 英语（美国）
        Locale('en', 'US'),
      ],
      // title: AppLocalizations.of(context)!.appTitle,
      /// 应用主题配置
      theme: ThemeData(
        /// 启用 Material 3 设计规范
        useMaterial3: true,
        /// 设置自定义字体为 HarmonyOS Sans SC
        fontFamily: 'HarmonyOS_SansSC'
      ),
      // locale: const Locale('en', 'US'),
      /// 应用初始页面为 PDF 列表页面
      home: const PdfListScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'package:lite_view/screens/pdf_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    Directory path;
    if (Platform.isAndroid) {
      path = await getExternalStorageDirectory() ?? await getApplicationSupportDirectory();
    }
    else {
      path = await getApplicationSupportDirectory();
    }
    print(path.path);
    await windowManager.ensureInitialized();
    Hive.init(path.path);
    windowManager.setTitle('轻阅屏');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '轻阅屏',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'HarmonyOS_SansSC'
      ),
      home: const PdfListScreen(),
    );
  }
}

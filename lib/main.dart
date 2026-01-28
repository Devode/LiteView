import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'package:lite_view/screens/pdf_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
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

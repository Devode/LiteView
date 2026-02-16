import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';

import 'package:lite_view/screens/pdf_list_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory path;

  if (Platform.isAndroid) {
    path = await getExternalStorageDirectory() ?? await getApplicationSupportDirectory();
  } else {
    path = await getApplicationSupportDirectory();
    print(path.path);
    await windowManager.ensureInitialized();
  }

  Hive.init(path.path);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // windowManager.setTitle('轻阅屏');
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      // title: AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'HarmonyOS_SansSC'
      ),
      // locale: const Locale('en', 'US'),
      home: const PdfListScreen(),
    );
  }
}

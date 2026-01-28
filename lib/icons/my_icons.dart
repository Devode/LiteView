import 'package:flutter/widgets.dart';

class MyIcons {
  MyIcons._();

  static const _kFontFam = 'MyIcons';
  static const String? _kFontPkg = null;

  // 橡皮擦图标 （Unicode f000）
  static const IconData eraser = IconData(
    0xf000,
    fontFamily: _kFontFam,
    fontPackage: _kFontPkg
  );

  // 画笔图标 （Unicode f001）
  static const IconData pan = IconData(
    0xf001,
    fontFamily: _kFontFam,
    fontPackage: _kFontPkg
  );
}
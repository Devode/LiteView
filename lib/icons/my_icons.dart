/// 导入 Flutter 核心组件库
import 'package:flutter/widgets.dart';

/// 自定义图标类
/// 定义应用中使用的自定义图标，这些图标来自自定义字体文件 MyIcons.ttf
class MyIcons {
  /// 私有构造函数，防止实例化此类
  MyIcons._();

  /// 字体族名称，与 assets/fonts/MyIcons.ttf 文件对应
  static const _kFontFam = 'MyIcons';
  /// 字体包名称，设置为 null 表示使用本地字体
  static const String? _kFontPkg = null;

  /// 橡皮擦图标
  /// 用于橡皮擦模式的工具按钮
  /// Unicode 编码：0xf000
  static const IconData eraser = IconData(
    0xf000,
    fontFamily: _kFontFam,
    fontPackage: _kFontPkg
  );

  /// 画笔/平移图标
  /// 用于平移模式的工具按钮
  /// Unicode 编码：0xf001
  static const IconData pan = IconData(
    0xf001,
    fontFamily: _kFontFam,
    fontPackage: _kFontPkg
  );
}
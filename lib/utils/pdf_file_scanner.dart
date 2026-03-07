/// 导入 Dart I/O 库，用于文件系统操作
import 'dart:io';
/// 导入路径操作库
import 'package:path/path.dart' as path;
/// 导入路径提供者库，用于获取应用支持目录
import 'package:path_provider/path_provider.dart';
/// 导入 JSON 文件处理器
import 'package:lite_view/utils/json_file_handler.dart';

/// 获取 PDF 文档列表（旧版本，使用 JSON 文件存储）
/// 从应用支持目录中读取 pdfDocs.json 文件，获取 PDF 文档信息
///
/// 注意：此函数是旧版本实现，已被使用 Hive 数据库的版本替代
/// 保留此函数仅用于向后兼容或迁移目的
///
/// 功能：
/// 1. 获取应用支持目录
/// 2. 读取 pdfDocs.json 文件
/// 3. 解析 JSON 数据为 Map 对象
///
/// 返回：PDF 文档信息的 Map 对象，键为文件名，值为文件路径
Future<Map<String, dynamic>> getPdfDocs() async {
  // 获取Application Support 目录
  final directory = await getApplicationSupportDirectory();
  final handler = JsonFileHandler(); // 创建Json文件处理器

  print('Documents 目录：${directory.path}');

  /// 初始化空的 PDF 文档 Map
  Map<String, dynamic> _pdfDocs = <String, File>{};

  /// 检查目录是否存在
  if (await directory.exists()) {
    /// 从 JSON 文件读取数据
    final jsonData = await handler.readJsonFormFile('pdfDocs.json');

    /// 如果读取成功，使用读取的数据；否则使用空 Map
    _pdfDocs = jsonData ?? <String, dynamic>{};

    print(_pdfDocs);
  }

  return _pdfDocs;
}
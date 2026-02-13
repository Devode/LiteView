import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:lite_view/utils/json_file_handler.dart';

Future<Map<String, dynamic>> getPdfDocs() async {
  // 获取Application Support 目录
  final directory = await getApplicationSupportDirectory();
  final handler = JsonFileHandler(); // 创建Json文件处理器

  print('Documents 目录：${directory.path}');

  Map<String, dynamic> _pdfDocs = <String, File>{};

  if (await directory.exists()) {
    final jsonData = await handler.readJsonFormFile('pdfDocs.json');

    _pdfDocs = jsonData ?? <String, dynamic>{};

    print(_pdfDocs);
  }

  return _pdfDocs;
}
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class JsonFileHandler {
  // 获取应用私有目录下的文件路径
  Future<File> _localFile(String filename) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$filename');
  }

  // 保存 JSON 数据到文件
  Future<void> saveJsonToFile(Map<String, dynamic> data, String filename) async {
    final file = await _localFile(filename);
    final jsonString = jsonEncode(data);
    await file.writeAsString(jsonString);
  }

  Future<Map<String, dynamic>?> readJsonFormFile(String filename) async {
    try {
      final file = await _localFile(filename);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('读取 JSON 文件出错：$e');
      return null;
    }
  }
}
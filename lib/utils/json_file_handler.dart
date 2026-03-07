/// 导入 JSON 编解码库，用于 JSON 数据的序列化和反序列化
import 'dart:convert';
/// 导入 Dart I/O 库，用于文件操作
import 'dart:io';
/// 导入路径提供者库，用于获取应用支持目录
import 'package:path_provider/path_provider.dart';

/// JSON 文件处理器类
/// 提供 JSON 文件的读写功能，用于数据的持久化存储
class JsonFileHandler {
  /// 获取应用私有目录下的文件路径
  ///
  /// 参数：
  /// - [filename] 文件名
  ///
  /// 返回：指向指定文件的 File 对象
  Future<File> _localFile(String filename) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$filename');
  }

  /// 保存 JSON 数据到文件
  /// 将 Map 数据编码为 JSON 字符串并写入文件
  ///
  /// 参数：
  /// - [data] 要保存的 JSON 数据（Map 类型）
  /// - [filename] 目标文件名
  Future<void> saveJsonToFile(Map<String, dynamic> data, String filename) async {
    final file = await _localFile(filename);
    final jsonString = jsonEncode(data);
    await file.writeAsString(jsonString);
  }

  /// 从文件读取 JSON 数据
  /// 读取文件内容并解码为 Map 对象
  ///
  /// 参数：
  /// - [filename] 要读取的文件名
  ///
  /// 返回：解码后的 Map 对象，如果文件不存在或读取失败则返回 null
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
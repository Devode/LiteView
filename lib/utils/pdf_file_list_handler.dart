/// 导入 Hive 本地数据库库
import 'package:hive/hive.dart';

/// 获取 PDF 文档列表
/// 从 Hive 数据库中读取已保存的 PDF 文档信息
///
/// 功能：
/// 1. 打开或创建 pdf_docs 数据库
/// 2. 读取 'docs' 键对应的数据
/// 3. 将数据转换为 Map<String, dynamic> 类型
/// 4. 处理可能的类型转换问题（Hive 可能存储为 dynamic 类型）
///
/// 返回：PDF 文档信息的 Map 对象，键为文件名，值为文件路径
Future<Map<String, dynamic>> getPdfDocs() async {
  /// 打开或创建 pdf_docs 数据库
  final box = await Hive.openBox('pdf_docs');

  /// 从数据库获取 PDF 文档信息
  final data = box.get('docs');

  // 如果 data 为 null，返回空 map
  if (data == null) {
    return <String, dynamic>{};
  }

  // 安全地将 Map<dynamic, dynamic> 转为 Map<String, dynamic>
  if (data is Map) {
    final Map<String, dynamic> result = {};
    data.forEach((key, value) {
      // 确保 key 是 String 类型（Hive 存的时候应该是 String）
      if (key is String) {
        result[key] = value;
      } else {
        // 可选：处理非 String key（比如数字 key），通常不应该出现
        result[key.toString()] = value;
      }
    });
    return result;
  }

  // 如果 data 不是 Map 类型（异常情况）
  return <String, dynamic>{};
}

/// 保存 PDF 文档信息
/// 将 PDF 文档信息保存到 Hive 数据库
///
/// 参数：
/// - [docs] PDF 文档信息的 Map 对象，键为文件名，值为文件路径
Future<void> savePdfDocsInfo(Map<String, dynamic> docs) async {
  /// 打开或创建 pdf_docs 数据库
  final box = await Hive.openBox('pdf_docs');
  /// 将文档信息保存到数据库
  await box.put('docs', docs);
}
import 'package:hive/hive.dart';

Future<Map<String, dynamic>> getPdfDocs() async {
  final box = await Hive.openBox('pdf_docs');

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

Future<void> savePdfDocsInfo(Map<String, dynamic> docs) async {
  final box = await Hive.openBox('pdf_docs');
  await box.put('docs', docs);
}
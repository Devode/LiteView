/// lib/utils/import_pdf.dart
/// PDF 文件导入工具
/// 负责将 PDF 文件导入到应用中，并管理文件名冲突

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:lite_view/utils/json_file_handler.dart';

/// 导入 PDF 文件
/// 将指定路径的 PDF 文件添加到应用的文档列表中
///
/// 功能：
/// 1. 从 Hive 数据库读取已有的 PDF 文档列表
/// 2. 处理文件名冲突（如果文件名已存在，自动添加数字后缀）
/// 3. 将新文档信息保存到数据库
/// 4. 返回导入的文件对象
///
/// 参数：
/// - [sourcePath] 源文件的完整路径
///
/// 返回：导入的 File 对象，如果导入失败则返回 null
Future<File?> importPdf(String sourcePath) async {
  /// 打开或创建 pdf_docs 数据库
  final box = await Hive.openBox('pdf_docs'); // 打开pdf_docs数据库

  /// 从数据库获取 PDF 文档信息，如果不存在则创建空 Map
  final data = box.get('docs') ?? <String, dynamic>{}; // 获取pdf_docs数据库中的pdf文档信息

  /// 确保 Map 的键为 String 类型（Hive 可能存储为 dynamic 类型）
  var pdfDocsMap = data;
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
    pdfDocsMap = result;
  }

  /// 获取源文件名
  String fileName = path.basename(sourcePath);

  /// 处理文件名冲突
  int fileNameCounter = 1;
  final nameWithoutExt = path.basenameWithoutExtension(fileName); // 获取文件名，不包含扩展名
  final ext = path.extension(fileName); // 获取文件扩展名
  // 检查文件名是否已存在，如果已存在，则添加数字后缀（如：pdf(1).pdf）
  while (pdfDocsMap.containsKey(fileName)) {
    final newName = '$nameWithoutExt($fileNameCounter)$ext';
    fileName = newName;
    fileNameCounter++;
  }

  // 在pdfDocsMap中添加新文档信息
  pdfDocsMap[fileName] = sourcePath;
  // 保存pdf文档信息
  await box.put('docs', pdfDocsMap);
  // 创建目标文件
  final targetFile = File(sourcePath);
  return targetFile;
  // final handler = JsonFileHandler(); // 实例化JsonFileHandler
  // // 读取pdfDocs.json文件
  // final loadedData = await handler.readJsonFormFile('pdfDocs.json');
  // // 创建一个Map对象，用于存储pdf文档信息，若读取失败，则创建一个空的Map对象
  // Map<String, dynamic> pdfDocsMap = loadedData ?? <String, dynamic>{};
  //
  // var fileName = path.basename(sourcePath);
  //
  // // 如果已存在相同的文件路径，则直接返回该文件
  // if (pdfDocsMap.containsValue(sourcePath)) {
  //   return File(sourcePath);
  // }
  //
  // // 检查文件名是否已存在，如果已存在，则添加数字后缀（如：pdf(1).pdf）
  // int counter = 1;
  // while (pdfDocsMap.containsKey(fileName)) {
  //   final nameWithoutExt = path.basenameWithoutExtension(fileName);
  //   final ext = path.extension(fileName);
  //   final newName = '$nameWithoutExt($counter)$ext';
  //   fileName = newName;
  //   counter++;
  // }
  //
  // pdfDocsMap[fileName] = sourcePath;
  // // 保存pdf文档信息
  // await handler.saveJsonToFile(pdfDocsMap, 'pdfDocs.json');
  //
  // final targetFile = File(sourcePath);
  //
  // return targetFile;
}
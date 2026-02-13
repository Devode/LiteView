// lib/utils/import_pdf.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:lite_view/utils/json_file_handler.dart';

Future<File?> importPdf(String sourcePath) async {
  final box = await Hive.openBox('pdf_docs'); // 打开pdf_docs数据库

  final data = box.get('docs') ?? <String, dynamic>{}; // 获取pdf_docs数据库中的pdf文档信息

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

  String fileName = path.basename(sourcePath);

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
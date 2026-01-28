// lib/utils/import_pdf.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:lite_view/utils/json_file_handler.dart';

Future<File?> importPdf(String sourcePath) async {
  final handler = JsonFileHandler(); // 实例化JsonFileHandler
  // 读取pdfDocs.json文件
  final loadedData = await handler.readJsonFormFile('pdfDocs.json');
  // 创建一个Map对象，用于存储pdf文档信息，若读取失败，则创建一个空的Map对象
  Map<String, dynamic> pdfDocsMap = loadedData ?? <String, dynamic>{};

  var fileName = path.basename(sourcePath);

  // 如果已存在相同的文件路径，则直接返回该文件
  if (pdfDocsMap.containsValue(sourcePath)) {
    return File(sourcePath);
  }

  // 检查文件名是否已存在，如果已存在，则添加数字后缀（如：pdf(1).pdf）
  int counter = 1;
  while (pdfDocsMap.containsKey(fileName)) {
    final nameWithoutExt = path.basenameWithoutExtension(fileName);
    final ext = path.extension(fileName);
    final newName = '$nameWithoutExt($counter)$ext';
    fileName = newName;
    counter++;
  }

  pdfDocsMap[fileName] = sourcePath;
  // 保存pdf文档信息
  await handler.saveJsonToFile(pdfDocsMap, 'pdfDocs.json');

  final targetFile = File(sourcePath);
  
  return targetFile;
}
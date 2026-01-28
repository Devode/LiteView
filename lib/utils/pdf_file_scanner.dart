import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:lite_view/utils/json_file_handler.dart';

Future<Map<String, dynamic>> getPdfDocs() async {
  final directory = await getApplicationSupportDirectory();
  final handler = JsonFileHandler();

  print('Documents 目录：${directory.path}');
  final List<File> pdfFiles = [];

  Map<String, dynamic> _pdfDocs = <String, File>{};

  if (await directory.exists()) {
    // final files = await directory.list().toList();
    // for (final file in files) {
    //   if (file is File && path.extension(file.path).toLowerCase() == '.pdf') {
    //     pdfFiles.add(file);
    //   }
    // }
    final jsonData = await handler.readJsonFormFile('pdfDocs.json');
    // if (jsonData == null) {
    //   final pdfDocs = jsonData?.values.toList();
    //   final pdfNames = jsonData?.keys.toList();
    //   for (final pdfDoc in pdfDocs ?? []) {
    //     final pdfFile = File(pdfDoc);
    //     if (await pdfFile.exists() && path.extension(pdfFile.path).toLowerCase() == '.pdf') {
    //       pdfFiles.add(pdfFile);
    //     }
    //   }
    // }

    _pdfDocs = jsonData ?? <String, dynamic>{};

    print(_pdfDocs);

    // _pdfDocs = jsonData ?? <String, dynamic>{};
    // 按修改时间倒序（最新在前）
    // pdfFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  return _pdfDocs;
}
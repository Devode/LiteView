import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lite_view/data_types/data_types.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService extends ChangeNotifier {
  final Dio _dio = Dio();
  bool isDownloading = false;
  double progress = 0.0;
  String? currentFileName;
  List<DownloadFile> downloadingFiles = [];

  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// 开始下载
  /// - [url] 下载地址
  /// - [fileName] 文件名
  /// - [isTemporary] 是否临时文件，默认为 false，若为 true，则下载完成后会删除临时文件
  Future<void> startDownload(BuildContext context, String url, String fileName, {bool isTemporary = false}) async {
    for (var file in downloadingFiles) {
      if (file.name == fileName) {
        print("文件已存在");
        return;
      }
    }
    downloadingFiles.add(DownloadFile(
      name: fileName,
      url: url,
      isTemporary: isTemporary,
      progress: 0.0
    ));
    notifyListeners();
    if (isDownloading) return;

    isDownloading = true;
    currentFileName = fileName;
    notifyListeners();

    final tempDir = await getTemporaryDirectory();
    final supportDir = await getApplicationSupportDirectory();

    try {
      int index = 0;
      while (index < downloadingFiles.length) {
        final savePath = downloadingFiles[index].isTemporary ? (Platform.isWindows ? '${tempDir.path}\\' :'${tempDir.path}/') : (Platform.isWindows ? '${supportDir.path}\\downloads\\' :'${supportDir.path}/downloads/');

        currentFileName = downloadingFiles[index].name;
        final finalSavePath = savePath + currentFileName!;

        await _dio.download(
          downloadingFiles[index].url,
          finalSavePath,
          onReceiveProgress: (received, total) {
            progress = received / total;
            downloadingFiles[index].progress = progress;
            notifyListeners();
          }
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("下载完成: $currentFileName，已保存至：$finalSavePath"),
          )
        );

        index++;
      }

      print("下载完成");
    } catch (e) {
      print("下载失败: $e");
    } finally {
      print("下载完成");
      isDownloading = false;
      notifyListeners();
    }

  }
}
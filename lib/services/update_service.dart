import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lite_view/l10n/app_localizations.dart';
import 'package:lite_view/services/download_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  final DownloadService downloadService = DownloadService();
  final String owner = 'devode';
  final String repo = 'lite_view';

  // 获取本地版本
  Future<String> getLocalVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  // 检查更新
  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final url = Uri.parse(
        'https://gitee.com/api/v5/repos/$owner/$repo/releases/latest'
      );

      // 发送 GET 请求
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      // 如果响应成功
      if (response.statusCode == 200) {
        final data = json.decode(response.body); // 解析 JSON 数据

        // 获取版本号和下载链接
        final String remoteVersionTag = data['tag_name'];
        final String releaseUrl = 'https://gitee.com/$owner/$repo/releases/tag/$remoteVersionTag'; //data['html_url'];
        final String body = data['body'] ?? '无更新日志';

        // 获取远程与本地版本
        final cleanRemoteVersion = remoteVersionTag.replaceFirst('v', '').replaceFirst('V', '');
        final localVersion = await getLocalVersion();

        // 比较版本
        final Version localVer =  Version.parse(localVersion);
        final Version remoteVer = Version.parse(cleanRemoteVersion);

        if (remoteVer > localVer) { // 远程版本大于本地版本
          // 尝试获取下载链接
          String? directDownloadUrl;
          if (data['assets'] is List) {
            for (var asset in data['assets']) {
              if (asset['name'].toString().endsWith('.apk') && Platform.isAndroid) {
                directDownloadUrl = asset['browser_download_url'];
                break;
              }
              if (asset['name'].toString().endsWith('.exe') && Platform.isWindows) {
                directDownloadUrl = asset['browser_download_url'];
                break;
              }
            }
          }

          // 返回更新信息
          return {
            'hasUpdate': true,
            'version': cleanRemoteVersion,
            'url': directDownloadUrl ?? releaseUrl, // 若获取下载链接失败，则使用发布页面链接
            'notes': body,
            'isDirectAppPackage': directDownloadUrl != null, // 是否为直接下载的安装包
          };
        }
      } else {
        debugPrint('Gitee API 错误：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('检查更新时出错：$e');
    }
    return null;
  }

  void showUpdateDialog(BuildContext context, Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${AppLocalizations.of(context)!.newVersionAvailable}: v${updateInfo['version']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.updateNote),
              const SizedBox(height: 8),
              Text(updateInfo['notes'])
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final Uri url = Uri.parse(updateInfo['url']);
              if (updateInfo['isDirectAppPackage']) {
                downloadService.startDownload(context, url.toString(), 'lite_view_installer');
                if (Platform.isAndroid) {

                }
              }
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(updateInfo['isDirectAppPackage'] ? AppLocalizations.of(context)!.downloadNow : AppLocalizations.of(context)!.viewDetails),
          )
        ],
      )
    );
  }
}
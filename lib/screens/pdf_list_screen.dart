/// 导入 Flutter Material Design 组件库
import 'package:flutter/material.dart';
/// 导入 Dart I/O 库，用于文件系统操作
import 'dart:io';
/// 导入文件选择器库，用于让用户选择文件
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
/// 导入窗口管理器库，用于桌面窗口管理
import 'package:window_manager/window_manager.dart';
// import '../utils/pdf_file_scanner.dart';
import '../services/update_service.dart';
/// 导入 PDF 文件列表处理工具
import '../utils/pdf_file_list_handler.dart';
/// 导入 PDF 导入功能
import '../utils/import_pdf.dart';
/// 导入 JSON 文件处理器
import 'package:lite_view/utils/json_file_handler.dart';
/// 导入 PDF 查看页面
import 'pdf_view_page.dart';
/// 导入应用本地化支持
import 'package:lite_view/l10n/app_localizations.dart';

/// PDF 列表页面组件
/// 显示已导入的 PDF 文件列表，支持导入和移除 PDF 文件
class PdfListScreen extends StatefulWidget {
  const PdfListScreen({super.key});

  @override
  State<PdfListScreen> createState() => _PdfListScreenState();
}

/// PDF 列表页面的状态管理类
/// 负责 PDF 文件列表的加载、显示、导入和移除功能
class _PdfListScreenState extends State<PdfListScreen> {
  /// JSON 文件处理器实例，用于读写 PDF 文档信息
  final jsonHandler = JsonFileHandler();

  /// PDF 文件列表的 Future 对象，用于异步加载文件
  late Future<List<File>> _pdfFilesFuture;
  /// PDF 文档信息映射，键为文件名，值为文件路径
  late Map<String, dynamic> _pdfDocs;
  /// 删除窗口中选中的文件索引（可为 null 表示未选中）
  int? _selectedFileIndex; // 删除窗口选中选中文件的索引
  /// PDF 文件列表
  List<File> pdfFiles = []; // PDF 文件列表
  /// PDF 文件名列表
  List<String> pdfFileNames = []; // PDF 文件名列表

  /// 初始化状态
  /// 设置窗口标题并加载 PDF 文件列表
  @override
  void initState() {
    super.initState();
    // windowManager.setTitle("轻阅屏");
    /// 加载 PDF 文件列表
    _loadPdfFiles();
    /// 在第一帧绘制完成后设置窗口标题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      windowManager.setTitle(AppLocalizations.of(context)!.appName);
    });

    if (mounted) {
      checkForUpdates(isAppLaunching: true);
    }
  }

  void checkForUpdates({bool isAppLaunching = false}) async {
    UpdateService updateService = UpdateService();
    Map<String, dynamic>? updateInfo = await updateService.checkForUpdates();
    if (updateInfo != null && updateInfo['hasUpdate'] == true) {
      updateService.showUpdateDialog(context, updateInfo);
    } else if (!isAppLaunching) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('当前已是最新版本'))
      );
    }
  }

  /// 加载 PDF 文件列表
  /// 重新创建 Future 对象以触发列表刷新
  void _loadPdfFiles() {
    setState(() {
      _pdfFilesFuture = _getPdfFilesFuture();
    });
  }

  /// 异步获取 PDF 文件列表
  /// 从 Hive 数据库中读取 PDF 文档信息，并构建 File 对象列表
  ///
  /// 返回：PDF 文件列表
  Future<List<File>> _getPdfFilesFuture() async {
    _pdfDocs = await getPdfDocs(); // 获取 PDF 文档列表
    pdfFileNames = _pdfDocs.keys.toList(); // 获取 PDF 文件名列表
    List<File> pdfFiles = [];
    // 加载 PDF 文件，并添加到 pdfFiles 中
    for (var file in _pdfDocs.values.toList()) {
      pdfFiles.add(File(file));
    }

    print(pdfFiles);
    return pdfFiles; // 返回 PDF 文件列表
  }

  /// 选择并导入 PDF 文件
  /// 使用文件选择器让用户选择 PDF 文件，然后将其添加到应用中
  ///
  /// 处理逻辑：
  /// 1. 打开文件选择器（仅允许选择 PDF 文件）
  /// 2. 检查文件是否已存在，避免重复导入
  /// 3. 调用 importPdf 函数导入文件
  /// 4. 导入成功后刷新列表
  /// 5. 处理各种错误情况，包括 Linux 平台的文件选择器兼容性问题
  Future<void> _pickAndImportPdf() async {
    try {
      // 打开文件选择器（仅 PDF）
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      /// 用户取消选择文件
      if (result == null) {
        return;
      }

      // 导入文件
      File file = File(result.files.single.path!);

      /// 检查文件是否已存在
      if (_pdfDocs.values.toList().contains(file.path)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件已存在：${file.path.split('/').last}'),backgroundColor: Colors.red),
        );
        return;
      }

      try {
        // if (!mounted) return;
        /// 导入 PDF 文件
        final importedFile = await importPdf(file.path);
        print(importedFile);
        /// 导入成功，显示提示并刷新列表
        if (importedFile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入：${importedFile.path.split('/').last}')),
          );
          _loadPdfFiles();
        }
      } catch (e) {
        /// 导入失败，显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e，文件路径：${file.path}'),backgroundColor: Colors.red),
        );
      }
    } catch (e, stack) {
      // 检查是否是 Linux 系统
      if (Platform.isLinux) {
        final errorMessage = e.toString();
        // 判断是否是 portal 服务缺失错误（可选：更精确匹配）
        if (errorMessage.contains('org.freedesktop.portal.Desktop') ||
          errorMessage.contains('ServiceUnknown')) {

          // 弹出提示
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('文件选择器无法启动'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '您的系统缺少必要的桌面集成组件。\n\n'
                      '请在终端中运行以下命令安装：',
                    ),
                    const SizedBox(height: 12,),
                    SelectableText(
                      'sudo apt update && sudo apt install -y xdg-desktop-portal xdg-desktop-portal-gtk',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                    Text(
                      '\n错误信息：$errorMessage',
                      style: TextStyle(color: Colors.red),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('关闭'),
                ),
              ],
            )
          );
          return;
        }
      }

      /// 显示文件选择器启动失败的错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件选择器启动失败：$e')),
      );
    }

  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('无法打开 $url');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            tooltip: AppLocalizations.of(context)!.more,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
            onSelected: (String result) {
              // 处理选中项
              if (result == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: AppLocalizations.of(context)!.appName,
                  applicationVersion: '1.0.0',
                  applicationIcon: Image.asset('assets/icon/app_icon.png', width: 64, height: 64),
                  applicationLegalese: 'Copyright © 2026. Devode.\n'
                      '${AppLocalizations.of(context)!.legaleseLicense}',
                  children: [
                    Text(
                        AppLocalizations.of(context)!.description
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          child: Text(AppLocalizations.of(context)!.githubRepositoryLink),
                          onPressed: () {
                            _launchUrl('https://github.com/Devode/LiteView');
                          },
                        ),
                        TextButton(
                          child: Text(AppLocalizations.of(context)!.giteeRepositoryLink),
                          onPressed: () {
                            _launchUrl('https://gitee.com/devode/lite_view');
                          },
                        )
                      ],
                    )
                  ]
                );
              }
              else if (result == 'checkForUpdate') {
                checkForUpdates();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.about),
                  ],
                )
              ),
              PopupMenuItem(
                value: 'checkForUpdate',
                child: Row(
                  children: [
                    const Icon(Icons.arrow_circle_up),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.checkForUpdates),
                  ],
                ),
              ),
            ],
          )
        ],
        elevation: 4,
        shadowColor: Colors.black,
      ),
      body: FutureBuilder<List<File>>(
        future: _pdfFilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center( // 无文件
              child: Text(
                AppLocalizations.of(context)!.emptyPdfListText,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          } else {
            pdfFiles = snapshot.data!;
            return ListView.builder(
              itemCount: pdfFiles.length,
              itemBuilder: (context, index) {
                final file = pdfFiles[index];
                final fileName = pdfFileNames[index];
                final modified = file.lastModifiedSync();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.modificationTime(_formatDate(modified)),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.filePath(file.path),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )

                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerPage(pdfPath: file.path),
                        )
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8,
        children: [
          FloatingActionButton(
            heroTag: 'import_pdf',
            tooltip: AppLocalizations.of(context)!.importPDF,
            onPressed: _pickAndImportPdf,
            child: const Icon(Icons.upload_file),
          ),
          FloatingActionButton(
            heroTag: 'remove_pdf',
            tooltip: AppLocalizations.of(context)!.removePDF,
            onPressed: _showDeleteWindow,
            child: Icon(Icons.playlist_remove),
          )
        ],
      )
    );
    // FloatingActionButton
  }

  /// 格式化日期时间为字符串
  /// 将 DateTime 对象格式化为 "YYYY-MM-DD HH:mm" 格式
  ///
  /// 参数：
  /// - [date] 要格式化的日期时间对象
  ///
  /// 返回：格式化后的日期时间字符串
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ' '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, "0")}';
  }

  /// 显示删除文件对话框
  /// 弹出一个对话框，让用户选择要移除的 PDF 文件
  ///
  /// 功能：
  /// 1. 显示所有 PDF 文件列表
  /// 2. 允许用户选择要移除的文件
  /// 3. 确认后从列表中移除文件（不会删除实际文件）
  /// 4. 刷新文件列表
  void _showDeleteWindow() {
    print(pdfFiles);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? selectedFileIndex = _selectedFileIndex;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.removePdfTitle),
              content: SizedBox(
                width: double.maxFinite,
                height: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.removePdfPrompt,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.removePdfNote,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey
                      ),
                    ),
                    if (pdfFiles.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: pdfFiles.length,
                          itemBuilder: (context, index) {
                            final isSelected = selectedFileIndex == index;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: isSelected? 4 : 0,
                              child: ListTile(
                                leading: Icon(
                                  Icons.picture_as_pdf,
                                  color: isSelected ? Colors.red : Colors.grey,
                                ),
                                title: Text(pdfFiles[index].path),
                                selected: isSelected,
                                // selectedTileColor: Colors.white,
                                onTap: () {
                                  setState(() => selectedFileIndex = index);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.cancel), // 取消
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.remove), // 移除
                  onPressed: () {
                    if (selectedFileIndex != null) {
                      Navigator.pop(context, selectedFileIndex);
                    } else {
                      showDialog( // 提示
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Text(AppLocalizations.of(context)!.removePdfWarn),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.ok),
                            )
                          ]
                        )
                      );
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text(AppLocalizations.of(context)!.removePdfWarn),
                      //   ),
                      // );
                    }
                  },
                ),
              ],

            );
          },
        );
      }
    ).then((result) {
      if (result != null && result is int) {
        // setState(() {
        //   pdfFiles.removeAt(result);
        //   _selectedFileIndex = null;
        // });
        _pdfDocs.remove(pdfFileNames[result]); // 从 PDF 文档字典中移除
        // jsonHandler.saveJsonToFile(_pdfDocs, 'pdfDocs.json'); // 保存到 JSON 文件
        savePdfDocsInfo(_pdfDocs);
        _loadPdfFiles(); // 重新加载 PDF 文件
      }
    });

  }
}
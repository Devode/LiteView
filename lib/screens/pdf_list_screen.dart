import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
// import '../utils/pdf_file_scanner.dart';
import '../utils/pdf_file_list_handler.dart';
import '../utils/import_pdf.dart';
import 'package:lite_view/utils/json_file_handler.dart';
import 'pdf_view_page.dart';
import 'package:lite_view/l10n/app_localizations.dart';

class PdfListScreen extends StatefulWidget {
  const PdfListScreen({super.key});

  @override
  State<PdfListScreen> createState() => _PdfListScreenState();
}

class _PdfListScreenState extends State<PdfListScreen> {
  final jsonHandler = JsonFileHandler();
  
  late Future<List<File>> _pdfFilesFuture;
  late Map<String, dynamic> _pdfDocs;
  int? _selectedFileIndex; // 删除窗口选中选中文件的索引
  List<File> pdfFiles = []; // PDF 文件列表
  List<String> pdfFileNames = []; // PDF 文件名列表

  @override
  void initState() {
    super.initState();
    // windowManager.setTitle("轻阅屏");
    _loadPdfFiles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      windowManager.setTitle(AppLocalizations.of(context)!.appName);
    });
  }

  void _loadPdfFiles() {
    setState(() {
      _pdfFilesFuture = _getPdfFilesFuture();
    });
  }

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

  Future<void> _pickAndImportPdf() async {
    try {
      // 打开文件选择器（仅 PDF）
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) {
        return;
      }

      // 导入文件
      File file = File(result.files.single.path!);

      if (_pdfDocs.values.toList().contains(file.path)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件已存在：${file.path.split('/').last}'),backgroundColor: Colors.red),
        );
        return;
      }

      try {
        // if (!mounted) return;
        final importedFile = await importPdf(file.path);
        print(importedFile);
        if (importedFile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入：${importedFile.path.split('/').last}')),
          );
          _loadPdfFiles();
        }
      } catch (e) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件选择器启动失败：$e')),
      );
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
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(AppLocalizations.of(context)!.description),
                    )
                  ]
                );
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
            ],
          )
        ],
        elevation: 4,
        shadowColor: Colors.black,
        // backgroundColor: Colors.pinkAccent,
        // foregroundColor: Colors.white,
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
                // final fileName = file.path.split('/').last;
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
            tooltip: AppLocalizations.of(context)!.importPDF,
            onPressed: _pickAndImportPdf,
            child: const Icon(Icons.upload_file),
          ),
          FloatingActionButton(
            tooltip: AppLocalizations.of(context)!.removePDF,
            onPressed: _showDeleteWindow,
            child: Icon(Icons.playlist_remove),
          )
        ],
      )
    );
    // FloatingActionButton
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ' '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, "0")}';
  }

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

  void _showImportGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('如何导入 PDF 文件？'),
        content: const Text('请将 PDF 文件复制到以下目录：\n\n'
          '[手机存储]/Android/data/com.devode.lit_view/files/Documents'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
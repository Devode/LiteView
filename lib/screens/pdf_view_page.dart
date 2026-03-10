/// 导入 Dart 异步编程支持
import 'dart:async';
/// 导入 Dart UI 库，用于颜色、偏移量等类型
import 'dart:ui';
/// 导入 Dart I/O 库，用于文件系统操作
import 'dart:io';

/// 导入 Flutter Material Design 组件库
import 'package:flutter/material.dart';
/// 导入 Flutter 服务库，用于系统服务调用
import 'package:flutter/services.dart';
/// 导入颜色选择器库，用于选择画笔颜色
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
/// 导入应用本地化支持
import 'package:lite_view/l10n/app_localizations.dart';
/// 导入 PDF 阅读器库
import 'package:pdfrx/pdfrx.dart';
/// 导入自定义图标
import 'package:lite_view/icons/my_icons.dart';
/// 导入窗口管理器库
import 'package:window_manager/window_manager.dart';

/// 导入数据类型定义
import 'package:lite_view/data_types/data_types.dart';
/// 导入 PDF 绘制工具
import 'package:lite_view/utils/pdf_aware_drawing_painter.dart';
/// 导入当前路径绘制组件
import 'package:lite_view/widgets/current_path_painter.dart';
/// 导入数学模型
import 'package:lite_view/utils/math_models.dart';
// import 'package:shared_preferences/shared_preferences.dart';

/// 工具模式枚举
/// 定义 PDF 查看器的三种交互模式
enum ToolMode {
  pan, // 平移模式：用于拖动查看 PDF 内容
  annotation, // 注释模式：用于在 PDF 上绘制批注
  eraser, // 橡皮擦模式：用于擦除已绘制的批注
}

/// PDF 查看页面组件
/// 提供 PDF 文件的查看、缩放、批注等功能
class PdfViewerPage extends StatefulWidget {
  final String pdfPath;

  const PdfViewerPage({super.key, required this.pdfPath});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

/// PDF 查看页面的状态管理类
/// 负责管理 PDF 查看器的所有交互功能，包括：
/// - PDF 文档加载和显示
/// - 页面切换和缩放
/// - 批注绘制（画笔模式）
/// - 批注擦除（橡皮擦模式）
/// - 工具栏设置
class _PdfViewerPageState extends State<PdfViewerPage> {
  /// 存储每一页的批注路径，键为页码，值为该页的所有绘制路径
  final Map<int, List<DrawingPath>> _pagePaths = {};
  /// 当前路径绘制器的全局键，用于访问和更新当前绘制的路径
  final GlobalKey<CurrentPathPainterState> _currentPathPainterKey = GlobalKey();

  /// 应用栏组件
  late final AppBar appBar = AppBar(
    title: Text(AppLocalizations.of(context)!.pdfReader),
  );
  /// PDF 查看器控制器，用于控制 PDF 的缩放、翻页等操作
  late PdfViewerController _controller;
  /// 上一个页面的窗口标题，用于返回时恢复窗口标题
  late String appName; // 上一个页面窗口标题

  /// 当前页码（从 1 开始）
  int currentPage = 1;
  /// 总页数
  int totalPages = 1;
  /// 是否正在加载 PDF
  bool _isLoading = true;

  /// 是否全屏
  bool _isFullScreen = true;

  /// 是否发生错误
  bool _isError = false;
  /// 错误信息
  String _errorMessage = '';

  /// 工具栏按钮大小
  double _toolButtonSize = 32.0; // 32.0
  /// 画笔粗细
  double _strokeWidth = 1.0;

  /// 当前画笔颜色
  Color _currentPenColor = Colors.red;

  /// 当前工具模式
  ToolMode _currentToolMode = ToolMode.pan;

  static const double _maxPageScale = 5.0;
  static const double _minPageScale = 0.5;
  static const double _scaleStep = 0.2;

  /// 初始化状态
  /// 设置屏幕方向、窗口管理器选项，并加载 PDF 文件
  @override
  void initState() {
    super.initState();
    /// 设置屏幕方向为横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    /// 桌面平台的窗口配置
    if (Platform.isWindows || Platform.isLinux) {
      /// 在第一帧绘制后设置窗口标题
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        windowManager.setTitle(AppLocalizations.of(context)!.pdfReader);
        appName = AppLocalizations.of(context)!.appName;

        if (await windowManager.isMaximized()) { // 如果窗口已最大化
          await windowManager.unmaximize(); // 确保窗口已取消最大化
          await Future.delayed(const Duration(milliseconds: 100)); // 等待窗口最小化完成
        }
        /// 设置全屏模式
        await windowManager.setFullScreen(true);
        if (mounted) {
          setState(() {
            _isFullScreen = true;
          });
        }
      });
    } else if (Platform.isAndroid)
    {
      /// Android 平台：设置沉浸式模式，隐藏系统 UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    /// 加载 PDF 文件
    _loadPdf();

  }


  /// 加载 PDF 文件
  /// 从指定路径加载 PDF 文件并初始化查看器控制器
  ///
  /// 功能：
  /// 1. 从文件系统读取 PDF 文件
  /// 2. 创建 PDF 查看器控制器
  /// 3. 设置监听器以响应视图变化
  Future<void> _loadPdf() async {

    try {
      // 从文件加载 PDF
      final file = File(widget.pdfPath);

      /// 确保组件仍然挂载
      if (mounted) {
        setState(() {
          /// 创建 PDF 查看器控制器
          _controller = PdfViewerController();
          /// 标记加载完成
          _isLoading = false;
          /// 添加监听器，当控制器状态改变时更新 UI
          _controller.addListener(() {
            setState(() {});
          });
        });
      }
    } catch (e) {
      /// 加载失败，显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loadPdfFailed(e.toString()))),
      );
    }
  }

  // ============ 缩放控制 ============

  /// 放大 PDF 视图
  /// 以当前缩放比例的增量进行放大，但不超过最大缩放限制
  void zoomIn() {
    final newZoom = (_controller.currentZoom + _scaleStep).clamp(_minPageScale, _maxPageScale);
    _controller.setZoom(_controller.centerPosition, newZoom);
  }

  /// 缩小 PDF 视图
  /// 以当前缩放比例的减量进行缩小，但不低于最小缩放限制
  void zoomOut() {
    final newZoom = (_controller.currentZoom - _scaleStep).clamp(_minPageScale, _maxPageScale);
    _controller.setZoom(_controller.centerPosition, newZoom);
  }

  /// 重置缩放比例
  /// 将 PDF 视图恢复到原始大小（100%）
  void resetZoom() {
    _controller.setZoom(_controller.centerPosition, 1.0);
  }

//  ============ 页面切换 ============

  /// 下一页
  /// 跳转到下一页，如果已在最后一页则跳转到第一页
  void nextPage() {
    if (totalPages > 0) {
      final goalPage = currentPage < totalPages ? currentPage + 1 : 1;
      _controller.goToPage(pageNumber: goalPage);
      /// 如果已在最后一页，显示提示信息
      if (!(currentPage < totalPages)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.navigationAtLastPage)),
        );
      }
    }
  }

  /// 上一页
  /// 跳转到上一页，如果已在第一页则跳转到最后一页
  void previousPage() {
    final goalPage = currentPage > 1 ? currentPage - 1 : totalPages;
    _controller.goToPage(pageNumber: goalPage);
    /// 如果已在第一页，显示提示信息
    if (!(currentPage > 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.navigationAtFirstPage))
      );
    }
  }

  //  ============ 工具模式切换 ============

  /// 切换工具模式
  /// 在平移、注释和橡皮擦模式之间切换
  ///
  /// 参数：
  /// - [mode] 要切换到的工具模式
  void _switchToolMode(ToolMode mode) {
    setState(() {
      _currentToolMode = mode;
    });
  }

  /// 获取按钮背景颜色
  /// 根据当前工具模式返回对应的按钮背景色
  ///
  /// 参数：
  /// - [mode] 按钮对应的工具模式
  ///
  /// 返回：如果是当前模式则返回灰色，否则返回透明
  Color _getButtonBackgroundColor(ToolMode mode) {
    return _currentToolMode == mode
        ? Colors.grey.shade300
        : Colors.transparent;
  }
  
  bool checkPageNumberValid(int pageNumber) {
    return (totalPages > 0) ? (pageNumber >= 1 && pageNumber <= totalPages) : false;
  }

  DrawingPath _withScreenCache(DrawingPath path) {
    final screenPoints = path.points
        .map((pdfPoint) => _controller.documentToLocal(pdfPoint))
        .toList();
    return DrawingPath(
      points: path.points,
      color: path.color,
      strokeWidth: path.strokeWidth,
      cachedScreenPoints: screenPoints,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    windowManager.setTitle(appName);
    windowManager.setFullScreen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: appBar,
        body: Center(child: CircularProgressIndicator(),),
      );
    }
    if (_isError) {
      return Scaffold(
        appBar: appBar,
        body: Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong(_errorMessage)),),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    PdfViewer.file(
                      widget.pdfPath,
                      controller: _controller,
                      params: PdfViewerParams(
                        onDocumentLoadFinished: (documentRef, succeeded) {
                          setState(() {
                            if (succeeded) {
                              totalPages = _controller.pageCount;
                            } else {
                              final listenable = documentRef.resolveListenable();
                              final error = listenable.error;
                              final stackTrace = listenable.stackTrace;
                              _isError = true;
                              _errorMessage = '$error\n$stackTrace';
                            }
                          });
                        },
                        onPageChanged: (pageNumber) {
                          setState(() {
                            currentPage = pageNumber!;
                          });
                        },
                        textSelectionParams: PdfTextSelectionParams(
                            enabled: false
                        )
                      ),
                    ),
                    _buildAnnotationPanel()
                  ],
                )
              ),
            ],
          ),

          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: _buildBottomToolbar(),
          // )
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16
              ),
              child: _buildBottomToolbar(),
            ),
          )

        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    // if (_toolButtonSize == null || _toolButtonSize! <= 0) {
    //   final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    //   // double _toolButtonSize = 32.0;
    //   _toolButtonSize = devicePixelRatio * 18.0;
    // }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 菜单按钮
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ]
          ),
          // 菜单按钮
          child: PopupMenuButton(
            icon: Icon(Icons.menu),
            iconSize: _toolButtonSize,
            tooltip: AppLocalizations.of(context)!.menuButton,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
            itemBuilder: (context) {
              return [
                // 退出全屏
                if (Platform.isWindows)
                PopupMenuItem(
                  value: "exitFullScreen",
                  child: Text(_isFullScreen
                      ? AppLocalizations.of(context)!.exitFullScreen
                      : AppLocalizations.of(context)!.enterFullScreen),
                  onTap: () async {
                    final newFullScreenState = !_isFullScreen; // 获取新的全屏状态
                    if (await windowManager.isMaximized() && newFullScreenState) { // 如果当前窗口已最大化且将要全屏，则取消最大化
                      await windowManager.unmaximize();
                      await Future.delayed(const Duration(milliseconds: 100)); // 等待窗口状态更新完成
                    }
                    windowManager.setFullScreen(newFullScreenState);
                    if (mounted) {
                      setState(() {
                        _isFullScreen = newFullScreenState;
                      });
                    }
                  },
                ),
                // 退出按钮
                PopupMenuItem(
                  value: "exit",
                  child: Text(AppLocalizations.of(context)!.exit),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),

              ];
            },
          )
        ),
        // ElevatedButton.icon(
        //   icon: Icon(Icons.menu),
        //   label: Text('菜单'),
        //   onPressed: () {},
        // ),

        // 工具栏
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ]
          ),
          child: Row(
            children: [
              // 平移模式按钮
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: _getButtonBackgroundColor(ToolMode.pan),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: IconButton(
                  icon: Icon(
                      MyIcons.pan,
                      color: _currentToolMode == ToolMode.pan ? Colors.blue : null),
                  onPressed: () => _switchToolMode(ToolMode.pan),
                  tooltip: AppLocalizations.of(context)!.panMode,
                  hoverColor: Colors.transparent,
                  iconSize: _toolButtonSize,
                ),
              ),
              // 注释模式按钮
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: _getButtonBackgroundColor(ToolMode.annotation),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: IconButton(
                  icon: Icon(Icons.edit,
                      color: _currentToolMode == ToolMode.annotation ? Colors.blue : null),
                  onPressed: () => _switchToolMode(ToolMode.annotation),
                  tooltip: AppLocalizations.of(context)!.annotationMode,
                  hoverColor: Colors.transparent,
                  iconSize: _toolButtonSize,
                ),
              ),
              // 橡皮擦模式按钮
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: _getButtonBackgroundColor(ToolMode.eraser),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: IconButton(
                  icon: Icon(
                      MyIcons.eraser,
                      color: _currentToolMode == ToolMode.eraser ? Colors.blue : null),
                  onPressed: () => _switchToolMode(ToolMode.eraser),
                  tooltip: AppLocalizations.of(context)!.eraserMode,
                  hoverColor: Colors.transparent,
                  iconSize: _toolButtonSize,
                ),
              ),

              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => clearAllAnnotations(),
                tooltip: AppLocalizations.of(context)!.clearButton,
                iconSize: _toolButtonSize,
              ),
            ],
          ),
        ),

        // 缩放控制
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ]
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.fit_screen),
                onPressed: () => resetZoom(),
                tooltip: AppLocalizations.of(context)!.fitToPageButton,
                iconSize: _toolButtonSize,
              ),
              IconButton(
                icon: Icon(Icons.zoom_in),
                onPressed: () => zoomIn(),
                tooltip: AppLocalizations.of(context)!.zoomInButton,
                iconSize: _toolButtonSize,
              ),
              IconButton(
                icon: Icon(Icons.zoom_out),
                onPressed: () => zoomOut(),
                tooltip: AppLocalizations.of(context)!.zoomOutButton,
                iconSize: _toolButtonSize,
              ),
              IconButton(
                icon: Icon(Icons.settings),
                tooltip: AppLocalizations.of(context)!.settingsButton,
                iconSize: _toolButtonSize,
                onPressed: () {
                  void Function(void Function()) mainSetState = setState;
                  double currentSize = _toolButtonSize; // 拷贝值
                  double strokeWidth = _strokeWidth;
                  Color currentPenColor = _currentPenColor;

                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (bottomContext, bottomSetState) {
                          // double currentSize = initialSize;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _settingsItem(
                                AppLocalizations.of(context)!.buttonScale(currentSize.round().toString()),
                                Slider(
                                  value: currentSize ?? 32,
                                  min: 16,
                                  max: 64,
                                  onChanged: (value) {
                                    currentSize = value;
                                    bottomSetState(() {});
                                  },
                                  onChangeEnd: (value) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        mainSetState(() => _toolButtonSize = value);
                                      }
                                    });
                                  },
                                )
                              ),
                              _settingsItem(
                                AppLocalizations.of(context)!.strokeWidth(strokeWidth.round().toString()),
                                Slider(
                                  value: strokeWidth,
                                  min: 1,
                                  max: 24,
                                  onChanged: (value) {
                                    strokeWidth = value;
                                    bottomSetState(() {});
                                  },
                                  onChangeEnd: (value) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        mainSetState(() => _strokeWidth = value);
                                      }
                                    });
                                  },
                                )
                              ),
                              _settingsItem(
                                AppLocalizations.of(context)!.brushColor,
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: currentPenColor,
                                  ),
                                  child: null,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(AppLocalizations.of(context)!.selectBrushColorTitle),
                                          content: SingleChildScrollView(
                                            child: ColorPicker(
                                              pickerColor: currentPenColor,
                                              onColorChanged: (color) {
                                                bottomSetState(() => currentPenColor = color);
                                              },
                                              // showLabel: true,
                                              enableAlpha:  false,
                                              pickerAreaHeightPercent: 0.7,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text(AppLocalizations.of(context)!.ok),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                // bottomSetState(() => currentPenColor = currentPenColor);
                                              },
                                            ),
                                          ],
                                        );
                                      }
                                    );
                                  },
                                )
                              ),
                            ],
                          );
                        },
                      );
                    }
                  ).then((_) {
                    if (mounted) setState(() => _currentPenColor = currentPenColor);
                  });
                },
              ),
            ],
          ),
        ),

        // 页码导航
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ]
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => previousPage(),
                tooltip: AppLocalizations.of(context)!.previousPageButton,
                iconSize: _toolButtonSize,
              ),
              Text(
                AppLocalizations.of(context)!.page,
                style: TextStyle(
                  // fontSize: _toolButtonSize / 2,
                  fontSize: _toolButtonSize * 0.5,
                ),
              ),
              TextButton(
                onPressed: () => _setPagePanel(),
                child: Text(
                  '$currentPage/$totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    // fontSize: _toolButtonSize / 2,
                    fontSize: _toolButtonSize * 0.5
                  ),
                ),
              ),
              // Text('$currentPage/$totalPages', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () => nextPage(),
                tooltip: AppLocalizations.of(context)!.nextPageButton,
                iconSize: _toolButtonSize,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnnotationPanel() {
    final pagePathsForPainter = <int, List<DrawingPath>>{};
    _pagePaths.forEach((page, paths) {
      pagePathsForPainter[page] = paths.map(_withScreenCache).toList();
    });

    final currentPathForPainter = _currentPath == null
      ? null
      : _withScreenCache(_currentPath!);

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: SizedBox.expand(
              child: CustomPaint(
                painter: PdfAwareDrawingPainter(
                  pagePaths: pagePathsForPainter,
                    currentPath: null,
                    currentPage: currentPage.clamp(1, totalPages),
                    controller: _controller,
                    screenSize: MediaQuery.of(context).size
                  ),
                ),
              )
          ),
        ),
        if ([ToolMode.annotation, ToolMode.eraser].contains(_currentToolMode))
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CurrentPathPainter(
                key: _currentPathPainterKey,
                // currentPath: _currentToolMode == ToolMode.annotation ? currentPathForPainter : null,
                currentPage: currentPage.clamp(1, totalPages),
                controller: _controller,
                screenSize: MediaQuery.of(context).size,
              ),
            ),
          ),
      ],
    );
  }

  Widget _settingsItem(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          child,
        ],
      ),
    );
  }
  
  void _setPagePanel() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.goToPageTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: AppLocalizations.of(context)!.goToPageInputTip),
            autofocus: true, // 自动聚焦，弹出键盘
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 取消
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
                onPressed: () {
                  // 将输入的页码转换为数字
                  final goalPage = int.tryParse(controller.text);
                  // 如果页码有效，则跳转到指定页码
                  if (goalPage != null && checkPageNumberValid(goalPage)) {
                    _controller.goToPage(pageNumber: goalPage);
                    Navigator.of(context).pop();
                  } else { // 否则显示错误提示
                    // 弹出错误提示
                    showDialog(
                        context: context,
                        builder: (BuildContext secondContext) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!.tip),
                            content: Text(AppLocalizations.of(context)!.goToPageInputError),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(secondContext).pop(),
                                child: Text(AppLocalizations.of(context)!.ok),
                              )
                            ],
                          );
                        }
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.ok),
            )
          ],
        );
      }
    );
  }

  /// 当前正在绘制的路径
  DrawingPath? _currentPath;
  /// 当前绘制路径所在的页码
  int? _currentPageForDrawing;

  /// 屏幕坐标转换为 PDF 坐标
  /// 将屏幕上的触摸位置转换为 PDF 文档坐标系中的位置
  ///
  /// 参数：
  /// - [screenOffset] 屏幕坐标偏移量
  ///
  /// 返回：PDF 坐标偏移量，如果转换失败则返回 null
  Offset? _screenToPdf(Offset screenOffset) {
    return _controller.localToDocument(Offset(screenOffset.dx, screenOffset.dy - appBar.preferredSize.height));
  }

  /// 手势开始回调
  /// 当用户开始在屏幕上拖动时调用
  ///
  /// 功能：
  /// - 仅在注释模式和橡皮擦模式下处理
  /// - 将屏幕坐标转换为 PDF 坐标
  /// - 根据当前模式开始绘制或擦除
  ///
  /// 参数：
  /// - [details] 拖动开始详情
  void _onPanStart(DragStartDetails details) {
    // 仅在注释模式和橡皮擦模式下处理
    if (![ToolMode.annotation, ToolMode.eraser].contains(_currentToolMode)) return;

    final pdfPoint = _screenToPdf(details.globalPosition); // 转换为PDF坐标
    if (pdfPoint == null) return; // 屏幕坐标转换失败，则忽略

    if (_currentToolMode == ToolMode.annotation) {
      /// 注释模式：开始新的绘制路径
      final screenPoint = _controller.documentToLocal(pdfPoint);
      _currentPageForDrawing = _controller.pageNumber;
      _currentPath = DrawingPath(
        points: [pdfPoint],
        color: _currentPenColor,
        strokeWidth: _strokeWidth,
        cachedScreenPoints: [screenPoint]
      );
    } else if (_currentToolMode == ToolMode.eraser) {
      /// 橡皮擦模式：执行擦除操作
      _currentPageForDrawing = _controller.pageNumber;
      eraseStroke(pdfPoint);
    }

    /// 更新当前路径绘制器
    _currentPathPainterKey.currentState?.updatePath(_currentPath);
  }

  /// 手势更新回调
  /// 当用户在屏幕上拖动时持续调用
  ///
  /// 功能：
  /// - 仅在注释模式且当前路径存在时处理
  /// - 将新的点添加到当前绘制路径中
  /// - 更新屏幕缓存的坐标点以优化性能
  ///
  /// 参数：
  /// - [details] 拖动更新详情
  void _onPanUpdate(DragUpdateDetails details) {
    // 在为注释模式时_currentPath为null，或者_currentPageForDrawing为null时忽略
    if ((_currentPath == null && _currentToolMode == ToolMode.annotation) ||
        _currentPageForDrawing == null) {
      return;
    }

    final pdfPoint = _screenToPdf(details.globalPosition);
    if (pdfPoint == null) return;
    // 只在同一页面内绘制
    if (_controller.pageNumber != _currentPageForDrawing) return;

    if (_currentToolMode == ToolMode.annotation) {
      /// 注释模式：添加新的点到当前路径
      final newScreenPoint = _controller.documentToLocal(pdfPoint);
      final updatedPath = DrawingPath(
        points: [..._currentPath!.points, pdfPoint],
        color: _currentPath!.color,
        strokeWidth: _currentPath!.strokeWidth,
        cachedScreenPoints: [..._currentPath!.cachedScreenPoints!, newScreenPoint],
      );

      _currentPath = updatedPath;
      _currentPathPainterKey.currentState?.updatePath(updatedPath);
    } else if (_currentToolMode == ToolMode.eraser) {
      /// 橡皮擦模式：继续擦除操作
      eraseStroke(pdfPoint);
    }
  }

  /// 手势结束回调
  /// 当用户停止拖动时调用
  ///
  /// 功能：
  /// - 将当前绘制的路径保存到对应页面的路径列表中
  /// - 清空当前路径和页码引用
  /// - 触发 UI 更新
  ///
  /// 参数：
  /// - [details] 拖动结束详情
  void _onPanEnd(DragEndDetails details) {
    if (_currentPath != null && _currentPageForDrawing != null) {
      List<Offset> simplifiedPoints = MathModels.simplifyPolyline(_currentPath!.points, 0.5);
      _currentPath = DrawingPath(
        points: simplifiedPoints,
        color: _currentPath!.color,
        strokeWidth: _currentPath!.strokeWidth,
        cachedScreenPoints: _currentPath!.cachedScreenPoints,
      );
      /// 将当前路径保存到对应页面的路径列表中
      _pagePaths.putIfAbsent(_currentPageForDrawing!, () => []).add(_currentPath!);

      _currentPathPainterKey.currentState?.updatePath(null);
      _currentPath = null;
      _currentPageForDrawing = null;

      setState(() {});
    }
  }

  /// 擦除绘制路径
  /// 检查并删除与指定点相交的绘制路径
  ///
  /// 功能：
  /// - 只处理当前页面的路径
  /// - 检查路径中的每个点是否在擦除半径内
  /// - 删除所有在擦除范围内的路径
  ///
  /// 参数：
  /// - [pdfPoint] PDF 坐标系中的擦除点
  void eraseStroke(Offset pdfPoint) {
    if (_currentPageForDrawing == null) return;

    // 只处理当前页的路径
    final currentPagePaths = _pagePaths[_currentPageForDrawing];
    if (currentPagePaths == null) return;

    final double eraseRadius = 10.0; // 擦除半径
    currentPagePaths.removeWhere((drawingPath) {
      // 检查路径中的每个点是否在擦除点半径内
      for (Offset point in drawingPath.points) {
        double distance = (point - pdfPoint).distance;
        if (distance <= eraseRadius) {
          return true; // 标记为删除
        }
      }
      return false; // 保留路径
    });

    setState(() {});
  }

  /// 清空所有批注
  /// 删除所有页面的所有绘制路径
  void clearAllAnnotations() {
    _pagePaths.clear();
    _currentPath = null;

    _currentPathPainterKey.currentState?.updatePath(_currentPath);
    setState(() {});
  }
}
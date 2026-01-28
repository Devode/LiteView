import 'dart:async';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:lite_view/icons/my_icons.dart';
import 'package:window_manager/window_manager.dart';

import 'package:lite_view/data_types/data_types.dart';
import 'package:lite_view/utils/pdf_aware_drawing_painter.dart';
import 'package:lite_view/widgets/current_path_painter.dart';
// import 'package:shared_preferences/shared_preferences.dart';

enum ToolMode {
  pan, // 平移模式
  annotation, // 注释模式
  eraser, // 橡皮擦模式
}

class PdfViewerPage extends StatefulWidget {
  final String pdfPath;

  const PdfViewerPage({super.key, required this.pdfPath});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final Map<int, List<DrawingPath>> _pagePaths = {};
  final AppBar appBar = AppBar(
    title: Text('PDF 阅读器'),
  );
  final Key _canvasKey = GlobalKey();
  final GlobalKey<CurrentPathPainterState> _currentPathPainterKey = GlobalKey();

  late PdfViewerController _controller;

  int currentPage = 1;
  int totalPages = 1;
  int _cachedVersion = 0;
  bool _isLoading = true;

  bool _isError = false;
  String _errorMessage = '';

  double _toolButtonSize = 32.0; // 32.0
  double _strokeWidth = 5.0;

  Color _currentPenColor = Colors.red;

  ToolMode _currentToolMode = ToolMode.pan;

  static const double _maxPageScale = 5.0;
  static const double _minPageScale = 0.5;
  static const double _scaleStep = 0.2;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (Platform.isWindows || Platform.isLinux) {
      windowManager.setTitle('PDF 阅读器');
      windowManager.maximize();
    } else if (Platform.isAndroid)
    {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    _loadPdf();

  }


  Future<void> _loadPdf() async {

    try {
      // 从文件加载 PDF
      final file = File(widget.pdfPath);
      // final data = await file.readAsBytes();

      if (mounted) {
        setState(() {
          _controller = PdfViewerController();
          // _document = doc;
          // _pdfData = data;
          _isLoading = false;
          _controller.addListener(() {
            setState(() {});
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载 PDF 失败: $e')),
      );
    }
  }

  void _onPdfViewChanged() {
    _cachedVersion++;
  }

  // 缩放
  // 放大
  void zoomIn() {
    final newZoom = (_controller.currentZoom + _scaleStep).clamp(_minPageScale, _maxPageScale);
    _controller.setZoom(_controller.centerPosition, newZoom);
  }
  // 缩小
  void zoomOut() {
    final newZoom = (_controller.currentZoom - _scaleStep).clamp(_minPageScale, _maxPageScale);
    _controller.setZoom(_controller.centerPosition, newZoom);
  }
  // 重置
  void resetZoom() {
    _controller.setZoom(_controller.centerPosition, 1.0);
  }

//  页面切换
//  上一页
  void nextPage() {
    if (totalPages > 0) {
      final goalPage = currentPage < totalPages ? currentPage + 1 : 1;
      _controller.goToPage(pageNumber: goalPage);
      if (!(currentPage < totalPages)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已到达最后一页，已返回第一页')),
        );
      }
    }
  }
  // 下一页
  void previousPage() {
    final goalPage = currentPage > 1 ? currentPage - 1 : totalPages;
    _controller.goToPage(pageNumber: goalPage);
    if (!(currentPage > 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已是第一页，已跳转到最后一页'))
      );
    }
  }
  // 切换模式
  void _switchToolMode(ToolMode mode) {
    setState(() {
      _currentToolMode = mode;
    });
  }
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
    // _controller.dispose();
    _controller.removeListener(() {});
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    windowManager.setTitle("轻阅屏");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.pdfPath);
    if (_isLoading) {
      return Scaffold(
        appBar: appBar,
        body: Center(child: CircularProgressIndicator(),),
      );
    }
    if (_isError) {
      return Scaffold(
        appBar: appBar,
        body: Center(child: Text('发生错误：$_errorMessage'),),
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
          child: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {},
            tooltip: '菜单',
            iconSize: _toolButtonSize,
          ),
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
                  tooltip: '平移模式',
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
                  tooltip: '注释模式',
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
                  tooltip: '橡皮擦模式',
                  hoverColor: Colors.transparent,
                  iconSize: _toolButtonSize,
                ),
              ),

              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => clearAllAnnotations(),
                tooltip: '清空',
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
                tooltip: '自适应',
                iconSize: _toolButtonSize,
              ),
              IconButton(
                icon: Icon(Icons.zoom_in),
                onPressed: () => zoomIn(),
                tooltip: '放大',
                iconSize: _toolButtonSize,
              ),
              IconButton(
                icon: Icon(Icons.zoom_out),
                onPressed: () => zoomOut(),
                tooltip: '缩小',
                iconSize: _toolButtonSize,
              ),
              IconButton(
                icon: Icon(Icons.settings),
                tooltip: '设置',
                iconSize: _toolButtonSize,
                onPressed: () {
                  void Function(void Function()) mainSetState = setState;
                  double? currentSize = _toolButtonSize; // 拷贝值
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
                                '缩放：${currentSize?.round()}',
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
                                '画笔粗细：${strokeWidth.round()}',
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
                                '画笔颜色',
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
                                          title: Text('选择画笔颜色'),
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
                                              child: Text('确定'),
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
                tooltip: '上一页',
                iconSize: _toolButtonSize,
              ),
              Text(
                '页数',
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
                tooltip: '下一页',
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
          title: Text("跳转到页码"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "输入页数"),
            autofocus: true, // 自动聚焦，弹出键盘
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 取消
              child: Text("取消"),
            ),
            TextButton(
                onPressed: () {
                  final goalPage = int.tryParse(controller.text);
                  print(goalPage);
                  if (goalPage != null && checkPageNumberValid(goalPage)) {
                    _controller.goToPage(pageNumber: goalPage);
                    Navigator.of(context).pop();
                  } else {
                    showDialog(
                        context: context,
                        builder: (BuildContext secondContext) {
                          return AlertDialog(
                            title: Text("提示"),
                            content: Text("请输入有效的页码"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(secondContext).pop(),
                                child: Text("确定"),
                              )
                            ],
                          );
                        }
                    );
                  }
                },
                child: Text("确定"),
            )
          ],
        );
      }
    );
  }

  DrawingPath? _currentPath;
  int? _currentPageForDrawing;

  Offset? _screenToPdf(Offset screenOffset) {
    return _controller.localToDocument(Offset(screenOffset.dx, screenOffset.dy - appBar.preferredSize.height));
  }

  void _onPanStart(DragStartDetails details) {
    // 仅在注释模式和橡皮擦模式下处理
    if (![ToolMode.annotation, ToolMode.eraser].contains(_currentToolMode)) return;

    final pdfPoint = _screenToPdf(details.globalPosition); // 转换为PDF坐标
    if (pdfPoint == null) return; // 屏幕坐标转换失败，则忽略

    if (_currentToolMode == ToolMode.annotation) {
      // setState(() {
      //   _currentPageForDrawing = _controller.pageNumber; // 当前页
      //   _currentPath = DrawingPath(
      //       points: [pdfPoint],
      //       color: Colors.red,
      //       strokeWidth: 5.0
      //   );
      // });
      final screenPoint = _controller.documentToLocal(pdfPoint);
      _currentPageForDrawing = _controller.pageNumber;
      _currentPath = DrawingPath(
        points: [pdfPoint],
        color: _currentPenColor,
        strokeWidth: _strokeWidth,
        cachedScreenPoints: [screenPoint]
      );
    } else if (_currentToolMode == ToolMode.eraser) {
      _currentPageForDrawing = _controller.pageNumber;
      eraseStroke(pdfPoint);
    }

    _currentPathPainterKey.currentState?.updatePath(_currentPath);
  }

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
      // setState(() {
      //   _currentPath = DrawingPath(
      //       points: [..._currentPath!.points, pdfPoint],
      //       color: _currentPath!.color,
      //       strokeWidth: _currentPath!.strokeWidth
      //   );
      // });
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
      eraseStroke(pdfPoint);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPath != null && _currentPageForDrawing != null) {
      _pagePaths.putIfAbsent(_currentPageForDrawing!, () => []).add(_currentPath!);
      // print("已保存的批注：${_currentPageForDrawing}");
      _currentPath = null;
      _currentPageForDrawing = null;
      setState(() {});
    }
  }

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

  void clearAllAnnotations() {
    _pagePaths.clear();
    _currentPath = null;

    _currentPathPainterKey.currentState?.updatePath(_currentPath);
    setState(() {});
  }
}
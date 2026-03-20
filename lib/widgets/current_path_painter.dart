/// 导入 Flutter Cupertino 组件库
import 'package:flutter/cupertino.dart';
/// 导入 PDF 阅读器库
import 'package:pdfrx/pdfrx.dart';
/// 导入数据类型定义
import 'package:lite_view/data_types/data_types.dart';
/// 导入 PDF 感知绘制画笔
import 'package:lite_view/utils/pdf_aware_drawing_painter.dart';

/// 当前路径绘制组件
/// 用于实时绘制用户当前正在拖动绘制的路径
/// 与已保存的批注路径分离，以优化性能和用户体验
class CurrentPathPainter extends StatefulWidget {
  // final DrawingPath? currentPath;
  final List<DrawingPath>? activePaths;
  /// 当前页码（从 1 开始）
  final int currentPage;
  /// PDF 查看器控制器
  final PdfViewerController controller;
  /// 屏幕尺寸
  final Size screenSize;

  /// 构造函数
  ///
  /// 参数：
  /// - [key] 组件的 Key
  /// - [currentPage] 当前页码
  /// - [controller] PDF 查看器控制器
  /// - [screenSize] 屏幕尺寸
  const CurrentPathPainter({
    super.key,
    this.activePaths,
    // this.currentPath,
    required this.currentPage,
    required this.controller,
    required this.screenSize
  });

  @override
  State<CurrentPathPainter> createState() => CurrentPathPainterState();
}

/// 当前路径绘制组件的状态管理类
/// 负责管理当前正在绘制的路径，并提供更新方法
class CurrentPathPainterState extends State<CurrentPathPainter> {
  /// 本地存储的当前绘制路径
  /// 使用本地状态而不是从外部传入，以便更灵活地控制重绘
  List<DrawingPath>? _localCurrentPath; // 自己的状态，只用于触发自身重绘

  // @override
  // void didUpdateWidget(covariant CurrentPathPainter oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // 当外部传入的 currentPath 改变时，同步到本地
  //   if (widget.currentPath != oldWidget.currentPath) {
  //     _localCurrentPath = widget.currentPath;
  //   }
  // }

  /// 更新当前路径
  /// 提供给 PdfViewerPage 调用的公共方法，用于更新当前绘制的路径
  ///
  /// 参数：
  /// - [newPath] 新的绘制路径，如果为 null 则清空当前路径
  void updatePath(List<DrawingPath>? newPath) {
    /// 确保组件仍然挂载
    if (mounted) {
      setState(() {
        _localCurrentPath = newPath;
      });
    }
  }

  /// 构建组件
  /// 返回一个使用 RepaintBoundary 优化的 CustomPaint 组件
  ///
  /// 返回：包含绘制器的组件
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: PdfAwareDrawingPainter(
            pagePaths: const {}, // 只画当前路径
            currentPath: _localCurrentPath,
            currentPage: widget.currentPage,
            controller: widget.controller,
            screenSize: widget.screenSize,
        ),
      ),
    );
  }
}
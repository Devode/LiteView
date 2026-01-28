import 'package:flutter/cupertino.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:lite_view/data_types/data_types.dart';
import 'package:lite_view/utils/pdf_aware_drawing_painter.dart';

class CurrentPathPainter extends StatefulWidget {
  // final DrawingPath? currentPath;
  final int currentPage;
  final PdfViewerController controller;
  final Size screenSize;

  const CurrentPathPainter({
    super.key,
    // this.currentPath,
    required this.currentPage,
    required this.controller,
    required this.screenSize,
  });

  @override
  State<CurrentPathPainter> createState() => CurrentPathPainterState();
}

class CurrentPathPainterState extends State<CurrentPathPainter> {
  DrawingPath? _localCurrentPath; // 自己的状态，只用于触发自身重绘

  // @override
  // void didUpdateWidget(covariant CurrentPathPainter oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // 当外部传入的 currentPath 改变时，同步到本地
  //   if (widget.currentPath != oldWidget.currentPath) {
  //     _localCurrentPath = widget.currentPath;
  //   }
  // }

  // 提供给 PdfViewerPage 调用的方法，用于更新路径
  void updatePath(DrawingPath? newPath) {
    if (mounted) {
      setState(() {
        _localCurrentPath = newPath;
      });
    }
  }

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
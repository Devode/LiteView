import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:lite_view/data_types/data_types.dart';

class PdfAwareDrawingPainter extends CustomPainter {
  final Map<int, List<DrawingPath>> pagePaths;
  final DrawingPath? currentPath;
  final int currentPage; // 期望 >=1
  final PdfViewerController controller;
  final Size screenSize;
  // Offset? lastScreenPosition;

  PdfAwareDrawingPainter({
    required this.pagePaths,
    this.currentPath,
    required this.currentPage,
    required this.controller,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // print("🎨 paint() called");
    // print("   - size:  $size");
    // print("   - currentPage:  $currentPage");
    // print("   - totalPages: (not available here)");
    // print("   - centerPosition:  ${controller.centerPosition}");
    // print("   - zoom:  ${controller.currentZoom}");
    // print("   - _pagePaths keys:  ${pagePaths.keys.toList()}");
    // ✅ 关键：防御性编程
    if (size.isEmpty || currentPage < 1) return;

    final centerPos = controller.centerPosition;
    final zoom = controller.currentZoom;
    if (zoom <= 0) return;

    final screenCenter = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    try {
      final paths = pagePaths[currentPage] ?? [];
      _drawPaths(canvas, paths, centerPos, zoom, paint);

      if (currentPath != null) {
        _drawPaths(canvas, [currentPath!], centerPos, zoom, paint);
      }
    } catch (e) {
      // 可选：开发时打印错误
      debugPrint("Drawing error:  $e");
    }
  }

  void _drawPaths(
      Canvas canvas,
      List<DrawingPath> paths,
      Offset centerPos,
      double zoom,
      Paint basePaint,
      ) {
    // 计算当前页起始 Y（PDF 文档坐标）
    // double pageStartY = 0;
    // // ✅ 确保 currentPage >=1
    // for (int i = 1; i < currentPage; i++) {
    //   pageStartY += _getPageHeight(i);
    // }

    for (final path in paths) {
      if (path.points.isEmpty) continue;

      basePaint.color = path.color;
      // basePaint.strokeWidth = (path.strokeWidth / zoom).clamp(1.0, 20.0); // 防止过细/过粗
      basePaint.strokeWidth = path.strokeWidth;
      // final screenPoints = <Offset>[];
      // final cachedScreenPoints = path.cachedScreenPoints;
      //
      // if (cachedScreenPoints == null ||
      //     cachedScreenPoints[0] != controller.documentToLocal(path.points[0])) {
      //   for (final pdfPoint in path.points) {
      //     // PDF 页内坐标 → 文档绝对坐标
      //     // final docPoint = Offset(pdfPoint.dx, pdfPoint.dy + pageStartY);
      //     // final docPoint = controller.
      //     // 文档坐标 → 屏幕坐标
      //     // final screenPoint = screenCenter + centerPos;
      //     final screenPoint = controller.documentToLocal(pdfPoint);
      //     screenPoints.add(screenPoint);
      //   }
      //   // path.cachedScreenPoints = screenPoints;
      // } else {
      //   screenPoints.addAll(cachedScreenPoints);
      // }
      final screenPoints = path.cachedScreenPoints!;

      if (screenPoints.length > 1) {
        canvas.drawPoints(PointMode.polygon, screenPoints, basePaint);
      } else if (screenPoints.length == 1) {
        canvas.drawCircle(screenPoints[0], path.strokeWidth / 2, basePaint);
      }
    }
  }

  // double _getPageHeight(int pageIndex) => 842.0;

  @override
  bool shouldRepaint(PdfAwareDrawingPainter oldDelegate) {
    return pagePaths != oldDelegate.pagePaths ||
        currentPath != oldDelegate.currentPath ||
        currentPage != oldDelegate.currentPage;
  }
}

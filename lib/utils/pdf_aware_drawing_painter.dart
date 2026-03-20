/// 导入 Dart UI 库，用于 Canvas 和 Paint 等类型
import 'dart:ui';
/// 导入 Flutter Cupertino 组件库
import 'package:flutter/cupertino.dart';
/// 导入 Flutter Material 组件库
import 'package:flutter/material.dart';
/// 导入 PDF 阅读器库
import 'package:pdfrx/pdfrx.dart';
/// 导入数据类型定义
import 'package:lite_view/data_types/data_types.dart';
/// 导入数学模型
import 'package:lite_view/utils/math_models.dart';

/// PDF 感知绘制画笔类
/// 自定义画笔，用于在 PDF 文档上绘制批注
/// 能够根据 PDF 的缩放和平移状态正确显示绘制内容
class PdfAwareDrawingPainter extends CustomPainter {
  /// 所有页面的批注路径映射，键为页码，值为该页的所有绘制路径
  final Map<int, List<DrawingPath>> pagePaths;
  /// 当前正在绘制的路径（可选）
  final List<DrawingPath>? currentPath;
  /// 当前页码（从 1 开始）
  final int currentPage; // 期望 >=1
  /// PDF 查看器控制器，用于获取缩放和位置信息
  final PdfViewerController controller;
  /// 屏幕尺寸
  final Size screenSize;
  // Offset? lastScreenPosition;

  /// 构造函数
  ///
  /// 参数：
  /// - [pagePaths] 所有页面的批注路径
  /// - [currentPath] 当前正在绘制的路径（可选）
  /// - [currentPage] 当前页码
  /// - [controller] PDF 查看器控制器
  /// - [screenSize] 屏幕尺寸
  PdfAwareDrawingPainter({
    required this.pagePaths,
    this.currentPath,
    required this.currentPage,
    required this.controller,
    required this.screenSize,
  });

  /// 绘制方法
  /// 在 Canvas 上绘制 PDF 文档的批注内容
  ///
  /// 功能：
  /// 1. 验证输入参数的有效性（防止空尺寸或无效页码）
  /// 2. 获取当前 PDF 的缩放和位置信息
  /// 3. 绘制当前页面的所有已保存批注
  /// 4. 绘制当前正在绘制的路径（如果有）
  ///
  /// 参数：
  /// - [canvas] Canvas 对象，用于绘制内容
  /// - [size] 绘制区域的尺寸
  @override
  void paint(Canvas canvas, Size size) {
    // print("🎨 paint() called");
    // print("   - size:  $size");
    // print("   - currentPage:  $currentPage");
    // print("   - totalPages: (not available here)");
    // print("   - centerPosition:  ${controller.centerPosition}");
    // print("   - zoom:  ${controller.currentZoom}");
    // print("   - _pagePaths keys:  ${pagePaths.keys.toList()}");
    // 防御性编程
    if (size.isEmpty || currentPage < 1) return;

    /// 获取 PDF 查看器的中心位置和缩放比例
    late final Offset centerPos;
    late final double zoom;

    try {
      centerPos = controller.centerPosition ?? Offset.zero;
      zoom = controller.currentZoom;
    } catch (e) {
      debugPrint("获取 PDF Controller 中心位置和缩放比例时出错：$e");
      return;
    }

    if (zoom <= 0) return;

    // /// 计算屏幕中心点
    // final screenCenter = Offset(size.width / 2, size.height / 2);
    /// 创建画笔对象，设置画笔样式
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    try {
      /// 获取当前页面的批注路径
      final paths = pagePaths[currentPage] ?? [];
      /// 绘制已保存的批注路径
      _drawPaths(canvas, paths, centerPos, zoom, paint, false);

      /// 绘制当前正在绘制的路径
      if (currentPath != null) {
        for (final path in currentPath!) {
          _drawPaths(canvas, [path], centerPos, zoom, paint, true);
        }
      }
    } catch (e) {
      // 可选：开发时打印错误
      debugPrint("Drawing error:  $e");
    }
  }

  /// 绘制路径方法
  /// 将一组绘制路径绘制到 Canvas 上
  ///
  /// 功能：
  /// 1. 遍历所有路径
  /// 2. 为每条路径设置颜色和粗细
  /// 3. 使用缓存的屏幕坐标点绘制路径
  /// 4. 处理单点绘制（绘制为圆点）和多点绘制（绘制为折线）
  ///
  /// 参数：
  /// - [canvas] Canvas 对象
  /// - [paths] 要绘制的路径列表
  /// - [centerPos] PDF 查看器的中心位置
  /// - [zoom] 缩放比例
  /// - [basePaint] 基础画笔对象
  void _drawPaths(
      Canvas canvas,
      List<DrawingPath> paths,
      Offset centerPos,
      double zoom,
      Paint basePaint,
      bool isPreview
      ) {
    // 计算当前页起始 Y（PDF 文档坐标）
    // double pageStartY = 0;
    // // 确保 currentPage >=1
    // for (int i = 1; i < currentPage; i++) {
    //   pageStartY += _getPageHeight(i);
    // }

    /// 遍历所有路径
    for (final path in paths) {
      /// 跳过空路径
      if (path.points.isEmpty) continue;

      /// 设置路径颜色
      basePaint.color = path.color;
      /// 设置路径粗细
      basePaint.strokeWidth = (path.strokeWidth * zoom);//.clamp(1.0, 24.0); // 缩放后的路径粗细，并使用clamp()防止过细或过粗
      /// 使用缓存的屏幕坐标点（已预先转换为屏幕坐标）
      final screenPoints = path.cachedScreenPoints;

      if (screenPoints == null) {
        debugPrint("警告：未缓存屏幕坐标点，跳过");
        continue;
      }

      /// 绘制路径
      if (screenPoints.length > 1) {
        // 预览模式，绘制为折线
        if (isPreview) {
          /// 多点绘制为折线
          canvas.drawPoints(PointMode.polygon, screenPoints, basePaint);
        } else { // 正常模式，绘制为曲线
          canvas.drawPath(
              MathModels.toQuadraticBezierPath(screenPoints), basePaint);
        }
      } else if (screenPoints.length == 1) {
        /// 单点绘制为圆点
        canvas.drawCircle(screenPoints[0], path.strokeWidth / 2, basePaint);
      }
    }
  }

  // double _getPageHeight(int pageIndex) => 842.0;

  /// 判断是否需要重新绘制
  /// 当以下任一条件满足时返回 true：
  /// 1. 页面路径发生变化
  /// 2. 当前路径发生变化
  /// 3. 当前页码发生变化
  ///
  /// 参数：
  /// - [oldDelegate] 旧的画笔对象
  ///
  /// 返回：是否需要重新绘制
  @override
  bool shouldRepaint(PdfAwareDrawingPainter oldDelegate) {
    return pagePaths != oldDelegate.pagePaths ||
        currentPath != oldDelegate.currentPath ||
        currentPage != oldDelegate.currentPage;
  }
}

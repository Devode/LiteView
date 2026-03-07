/// 数据类型定义文件
/// 包含应用程序中使用的数据模型和类型定义
import 'dart:ui';

/// 绘制路径类
/// 用于存储在 PDF 文档上绘制的批注信息
class DrawingPath {
  /// 路径点列表，存储绘制路径的所有坐标点（PDF 文档坐标系）
  final List<Offset> points;

  /// 绘制颜色
  final Color color;

  /// 笔触宽度，单位为像素
  final double strokeWidth;

  /// 缓存的屏幕坐标点列表（可选）
  /// 用于优化绘制性能，避免每次都从 PDF 坐标转换为屏幕坐标
  final List<Offset>? cachedScreenPoints;

  /// 构造函数
  /// 创建一个新的绘制路径对象
  ///
  /// 参数：
  /// - [points] 路径点列表（必填）
  /// - [color] 绘制颜色（必填）
  /// - [strokeWidth] 笔触宽度（必填）
  /// - [cachedScreenPoints] 缓存的屏幕坐标点列表（可选）
  DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.cachedScreenPoints,
  });
}
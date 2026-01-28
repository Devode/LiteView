// 数据类型
import 'dart:ui';

class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final List<Offset>? cachedScreenPoints;

  DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.cachedScreenPoints,
  });
}
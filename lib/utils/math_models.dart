import 'dart:math' as math;
import 'dart:ui';

class MathModels {

  /// 获取点到线段距离
  /// - [x1] 线段起点x坐标, [y1] 线段起点y坐标;
  /// - [x2] 线段终点x坐标, [y2] 线段终点y坐标;
  /// - [x3] 点x坐标, [y3] 点y坐标.
  static double pointToLineDistance(
      double x1, double y1, // 线段起点，设为点A
      double x2, double y2, // 线段终点，设为点B
      double x3, double y3  // 点P
      // 过点P的垂线交线段AB于点C
      ) {
    // 计算向量AB
    double dx = x2 - x1;
    double dy = y2 - y1;

    // 如果向量AB为零向量，则点P到线段AB的距离为点P到点A的距离
    if (dx == 0 && dy == 0) {
      return math.sqrt((x3 - x1) * (x3 - x1) + (y3 - y1) * (y3 - y1));
    }

    // 计算向量AP
    double px = x3 - x1;
    double py = y3 - y1;

    double t = (px * dx + py * dy) / (dx * dx + dy * dy);

    // 钳制 t：确保垂足 C 落在线段 AB 上
    // 若 t<0，C 重合于 A；若 t>1，C 重合于 B
    if (t < 0.0) {
      t = 0.0;
    } else if (t > 1.0) {
      t = 1.0;
    }

    // 计算点C的坐标
    double cx = x1 + t * dx;
    double cy = y1 + t * dy;

    // 计算点P到线段AB的距离，即点P到点C的距离
    double distance = math.sqrt((x3 - cx) * (x3 - cx) + (y3 - cy) * (y3 - cy));


    return distance;
  }

  /// 线段简化
  /// [points] 线段点集合
  /// [tolerance] 线段简化阈值
  static List<Offset> simplifyPolyline(
      List<Offset> points, double tolerance) {
    // 线段点数小于3，直接返回
    if (points.length < 3) return points;

    if (tolerance < 0) {
      throw ArgumentError('简化阈值不能小于0');
    }

    // 获取线段起点和终点
    Offset firstPoint = points.first;
    Offset lastPoint = points.last;

    // 初始化最大距离和最大索引
    double maxDistance = 0.0;
    int maxIndex = -1;

    // 遍历线段点，计算每个点到线段起点和终点的距离，并找到最大的距离和索引
    for (int i = 1; i < points.length - 1; i++) {
      // 计算点到线段的距离
      double distance = pointToLineDistance(
        firstPoint.dx, firstPoint.dy,
        lastPoint.dx, lastPoint.dy,
        points[i].dx, points[i].dy
      );
      // 更新最大距离和索引
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // 如果最大距离大于阈值，则将最大距离的点作为分界点，将线段分割成两个子线段，分别进行简化
    if (maxDistance > tolerance) {
      // 分割线段，递归获取子线段中的简化路径点
      List<Offset> result1 = simplifyPolyline(points.sublist(0, maxIndex + 1), tolerance);
      List<Offset> result2 = simplifyPolyline(points.sublist(maxIndex), tolerance);

      return [...result1.sublist(0, result1.length - 1), ...result2];
    } else { // 否则，返回线段起点和终点
      return [firstPoint, lastPoint];
    }
  }

  /// 获取线段中距离起点和终点最远的点
  /// - [points] 笔迹点集合
  ///   - 点数 < 2，返回起点
  ///   - 点数 < 3, 返回线段起点和终点之间的中点
  ///   - 点数 >= 3，则返回线段中距离起点和终点最远的点
  static Offset findFarthestPoint(List<Offset> points) {
    // 线段点集合不能为空
    if (points.isEmpty) {
      throw ArgumentError('线段点集合不能为空');
    }

    // 线段点数小于2，直接返回起点
    if (points.length < 2) {
      return points.first;
    }

    // 获取线段起点和终点
    Offset start = points.first;
    Offset end = points.last;

    // 线段点数小于3，则返回线段起点和终点之间的中点
    if (points.length < 3) {
      double centerX = (end.dx - start.dx) / 2;
      double centerY = (end.dy - start.dy) / 2;

      return Offset(start.dx + centerX, start.dy + centerY);
    }

    // 初始化最大距离和最大索引
    double maxDistance = 0.0;
    int maxIndex = -1;

    // 遍历线段点，计算每个点到线段起点和终点的距离，并找到最大的距离和索引
    for (int i = 1; i < points.length - 1; i++) {
      // 计算点到线段距离
      double distance = pointToLineDistance(
        start.dx, start.dy,
        end.dx, end.dy,
        points[i].dx, points[i].dy
      );

      // 更新最大距离和索引
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    return points[maxIndex];
  }

  /// 获取二次贝塞尔曲线路径
  /// - [points] 笔迹点集合
  ///   - 点数 < 3，返回一条直线
  ///   - 点数 >= 3，则返回一条二次贝塞尔曲线
  static Path toQuadraticBezierPath(List<Offset> points) {
    // 笔迹点集合不能为空
    if (points.isEmpty) {
      throw ArgumentError('点集合不能为空');
    }

    // 初始化路径
    Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // 点数小于3，则返回一条直线
    if (points.length < 3) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // 遍历笔迹点，生成二次贝塞尔曲线
    for (int i = 1; i < points.length - 1; i++) {
      // 获取当前点和下一个点
      Offset pCurrent = points[i];
      Offset pNext = points[i + 1];

      // 计算中点，并以此为终点
      Offset midPoint = Offset(
        (pCurrent.dx + pNext.dx) / 2,
        (pCurrent.dy + pNext.dy) / 2
      );

      // 生成二次贝塞尔曲线
      path.quadraticBezierTo(
        pCurrent.dx, pCurrent.dy,
        midPoint.dx, midPoint.dy
      );
    }

    // 添加终点
    path.lineTo(points.last.dx, points.last.dy);

    return path;
  }
}
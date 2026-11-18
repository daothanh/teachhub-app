import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Viền nét đứt bo góc — DS dùng cho trạng thái "chờ/tạm" (card Chủ trung tâm,
/// tag "Sắp ra mắt", banner lỗi). Flutter không có sẵn `BorderStyle.dashed`.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.color,
    required this.radius,
    required this.child,
    this.width = 1.5,
  });

  final Color color;
  final double radius;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedRRectPainter(color, radius, width),
    child: child,
  );
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter(this.color, this.radius, this.width);

  final Color color;
  final double radius;
  final double width;
  static const _dash = 4.0;
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = width / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.width - width, size.height - width),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final PathMetric metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius || old.width != width;
}

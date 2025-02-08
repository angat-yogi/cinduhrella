import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class Roadmap extends CustomPainter {
  final int itemCount;

  Roadmap(this.itemCount);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    Path path = Path();
    double startX = size.width * 0.5; // Center the roadmap
    double startY = 50;
    double stepY = size.height / (itemCount + 1) * 2;

    path.moveTo(startX, startY);

    for (int i = 0; i < itemCount; i++) {
      double curveX = (i % 2 == 0) ? size.width * 0.75 : size.width * 0.25;
      double controlX1 = (i % 2 == 0) ? size.width * 0.6 : size.width * 0.4;
      double controlX2 = (i % 2 == 0) ? size.width * 0.9 : size.width * 0.1;
      double endY = startY + stepY;

      // Smooth circular path with more spacing
      path.cubicTo(controlX1, startY + stepY * 0.35, controlX2,
          startY + stepY * 0.65, curveX, endY);

      startY = endY;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

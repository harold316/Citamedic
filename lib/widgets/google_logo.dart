import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arc(Color color) {
      return Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
    }

    canvas.drawArc(rect, _rad(-38), _rad(-140), false, arc(_red));
    canvas.drawArc(rect, _rad(142), _rad(80), false, arc(_yellow));
    canvas.drawArc(rect, _rad(38), _rad(104), false, arc(_green));
    canvas.drawArc(rect, _rad(-38), _rad(76), false, arc(_blue));

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius, center.dy),
      Paint()
        ..color = _blue
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
  }

  double _rad(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

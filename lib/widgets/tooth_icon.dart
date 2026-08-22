import 'package:flutter/material.dart';

class ToothIcon extends StatelessWidget {
  const ToothIcon({super.key, this.color, this.size = 24});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final paintColor = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ToothPainter(paintColor)),
    );
  }
}

class _ToothPainter extends CustomPainter {
  _ToothPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.18, h * 0.36)
      ..cubicTo(w * 0.18, h * 0.12, w * 0.38, h * 0.10, w * 0.50, h * 0.12)
      ..cubicTo(w * 0.62, h * 0.10, w * 0.82, h * 0.12, w * 0.82, h * 0.36)
      ..lineTo(w * 0.80, h * 0.50)
      ..cubicTo(w * 0.80, h * 0.58, w * 0.74, h * 0.64, w * 0.68, h * 0.70)
      ..lineTo(w * 0.60, h * 0.88)
      ..cubicTo(w * 0.57, h * 0.96, w * 0.52, h * 0.94, w * 0.52, h * 0.84)
      ..lineTo(w * 0.50, h * 0.66)
      ..lineTo(w * 0.48, h * 0.84)
      ..cubicTo(w * 0.48, h * 0.94, w * 0.43, h * 0.96, w * 0.40, h * 0.88)
      ..lineTo(w * 0.32, h * 0.70)
      ..cubicTo(w * 0.26, h * 0.64, w * 0.20, h * 0.58, w * 0.20, h * 0.50)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ToothPainter oldDelegate) =>
      oldDelegate.color != color;
}

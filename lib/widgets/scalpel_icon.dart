import 'package:flutter/material.dart';

class ScalpelIcon extends StatelessWidget {
  const ScalpelIcon({super.key, this.color, this.size = 24});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final paintColor = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ScalpelPainter(paintColor)),
    );
  }
}

class _ScalpelPainter extends CustomPainter {
  _ScalpelPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.52, size.height * 0.52);
    canvas.rotate(-0.7);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final handle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, size.height * 0.18),
        width: size.width * 0.28,
        height: size.height * 0.56,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(handle, paint);

    final blade = Path()
      ..moveTo(-size.width * 0.10, -size.height * 0.08)
      ..lineTo(size.width * 0.12, -size.height * 0.10)
      ..lineTo(size.width * 0.04, -size.height * 0.50)
      ..quadraticBezierTo(
        -size.width * 0.18,
        -size.height * 0.28,
        -size.width * 0.16,
        -size.height * 0.16,
      )
      ..close();
    canvas.drawPath(blade, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScalpelPainter oldDelegate) =>
      oldDelegate.color != color;
}

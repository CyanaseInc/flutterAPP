
import 'package:flutter/material.dart';
class MessageTailPainter extends CustomPainter {
  final LinearGradient gradient;
  final bool isMe;

  MessageTailPainter({required this.gradient, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isMe) {
      path.moveTo(size.width, 0);
      path.cubicTo(size.width * 0.8, size.height * 0.3, size.width * 0.6, size.height * 0.7, size.width - 8, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.cubicTo(size.width * 0.2, size.height * 0.3, size.width * 0.4, size.height * 0.7, 8, size.height);
      path.lineTo(size.width, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
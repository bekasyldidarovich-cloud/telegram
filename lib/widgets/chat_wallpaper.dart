import 'package:flutter/material.dart';

class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TelegramWallpaperPainter(), child: child);
  }
}

class _TelegramWallpaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xff101820),
          Color(0xff071019),
          Color(0xff141015),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final paint = Paint()
      ..color = const Color(0x18ffffff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final softPaint = Paint()
      ..color = const Color(0x0fffffff)
      ..style = PaintingStyle.fill;

    const step = 62.0;
    for (double y = 18; y < size.height + step; y += step) {
      for (double x = 18; x < size.width + step; x += step) {
        final shiftedX = x + ((y / step).round().isEven ? 0 : 28);
        final center = Offset(shiftedX, y);
        canvas.drawCircle(center, 9, paint);
        canvas.drawCircle(center.translate(18, 18), 3, softPaint);
        canvas.drawLine(center.translate(-7, 0), center.translate(7, 0), paint);
        canvas.drawLine(center.translate(0, -7), center.translate(0, 7), paint);
        canvas.drawPath(
          Path()
            ..moveTo(center.dx + 24, center.dy - 11)
            ..quadraticBezierTo(
              center.dx + 39,
              center.dy - 18,
              center.dx + 44,
              center.dy - 3,
            )
            ..quadraticBezierTo(
              center.dx + 35,
              center.dy + 2,
              center.dx + 24,
              center.dy - 11,
            ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

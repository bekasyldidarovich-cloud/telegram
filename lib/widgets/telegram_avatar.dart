import 'package:flutter/material.dart';

class TelegramAvatar extends StatelessWidget {
  const TelegramAvatar({
    required this.label,
    required this.color,
    this.radius = 25,
    super.key,
  });

  final String label;
  final int color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(label);
    final baseColor = Color(color);
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            baseColor.withValues(alpha: 0.86),
            _lighten(baseColor),
          ],
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.58,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _lighten(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0))
        .toColor();
  }

  String _initialsFor(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) {
      return '?';
    }
    if (words.length == 1) {
      return words.first.characters.first.toUpperCase();
    }
    return '${words.first.characters.first}${words[1].characters.first}'
        .toUpperCase();
  }
}

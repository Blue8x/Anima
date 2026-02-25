import 'dart:math' as math;

import 'package:flutter/material.dart';

class StarfieldOverlay extends StatelessWidget {
  const StarfieldOverlay({
    super.key,
    this.seed = 42,
    this.starCount = 140,
  });

  final int seed;
  final int starCount;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _StarfieldPainter(seed: seed, starCount: starCount),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({required this.seed, required this.starCount});

  final int seed;
  final int starCount;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;
    final width = size.width;
    final height = size.height;

    for (var i = 0; i < starCount; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final radius = 0.4 + random.nextDouble() * 1.2;
      final isWarm = random.nextInt(5) == 0;
      final alpha = 90 + random.nextInt(120);

      paint.color = isWarm
          ? const Color(0xFFFFF2B3).withAlpha(alpha)
          : Colors.white.withAlpha(alpha);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.starCount != starCount;
  }
}

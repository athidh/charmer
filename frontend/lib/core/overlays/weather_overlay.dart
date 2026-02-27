import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_settings.dart';

class WeatherOverlay extends StatefulWidget {
  final WeatherState state;
  const WeatherOverlay({super.key, required this.state});

  @override
  State<WeatherOverlay> createState() => _WeatherOverlayState();
}

class _WeatherOverlayState extends State<WeatherOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          if (widget.state == WeatherState.rainy)
            CustomPaint(
              painter: RainPainter(animationValue: _controller.value),
              size: Size.infinite,
            ),
          if (widget.state == WeatherState.hot) ...[
            CustomPaint(
              painter: HeatShimmerPainter(animationValue: _controller.value),
              size: Size.infinite,
            ),
            _buildSunGlare(),
          ],
        ],
      ),
    );
  }

  Widget _buildSunGlare() {
    return Positioned(
      top: -100,
      right: -100,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 + (0.1 * sin(_controller.value * 2 * pi));
          return Opacity(
            opacity: 0.3,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 400,
                height: 400,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFFFB300),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RainPainter extends CustomPainter {
  final double animationValue;
  final List<Offset> drops = List.generate(
    50,
    (index) => Offset(Random().nextDouble(), Random().nextDouble()),
  );

  RainPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var drop in drops) {
      final x = drop.dx * size.width;
      final y = ((drop.dy + animationValue) % 1.0) * size.height;

      canvas.drawLine(Offset(x, y), Offset(x - 2, y + 15), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RainPainter oldDelegate) => true;
}

class HeatShimmerPainter extends CustomPainter {
  final double animationValue;

  HeatShimmerPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (double i = 0; i < size.width; i += 20) {
      final yOffset = 10 * sin((i / 50) + (animationValue * 2 * pi));
      path.addOval(Rect.fromLTWH(i, size.height * 0.4 + yOffset, 100, 2));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeatShimmerPainter oldDelegate) => true;
}

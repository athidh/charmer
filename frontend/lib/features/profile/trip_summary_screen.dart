import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../auth/splash_screen.dart';

class TripSummaryScreen extends StatefulWidget {
  final String produce;
  final double freshness;
  const TripSummaryScreen({
    super.key,
    this.produce = 'Produce',
    this.freshness = 0.89,
  });

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  String get _gradeLabel {
    if (widget.freshness >= 0.85) return 'EXCELLENT';
    if (widget.freshness >= 0.70) return 'GOOD';
    if (widget.freshness >= 0.50) return 'FAIR';
    return 'POOR';
  }

  @override
  Widget build(BuildContext context) {
    final freshnessPercent = (widget.freshness * 100).toInt();

    return Scaffold(
      body: Stack(
        children: [
          // Celebration particles
          AnimatedBuilder(
            animation: _celebrationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _CelebrationPainter(
                  progress: _celebrationController.value,
                ),
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Success icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.forestGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                      )
                      .fadeIn(),

                  const SizedBox(height: 20),

                  Text(
                    'Delivery Successful!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 10, end: 0),

                  const SizedBox(height: 4),

                  Text(
                    '${widget.produce} delivered with AI-optimized routing',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 28),

                  // Freshness Score Card
                  _buildScoreCard(freshnessPercent),

                  const SizedBox(height: 20),

                  // Stats Grid — 2x2
                  _buildStatGrid(),

                  const SizedBox(height: 28),

                  // Action buttons
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.forestGreen.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SplashScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Back to Dashboard',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: AppTheme.forestGreen,
                      side: BorderSide(
                        color: AppTheme.forestGreen.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Share Report',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int freshnessPercent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.forestGreen.withValues(alpha: 0.06),
            AppTheme.sunsetOrange.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.forestGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'FINAL FRESHNESS SCORE',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.forestGreen, AppTheme.forestGreenLight],
            ).createShader(bounds),
            child: Text(
              '$freshnessPercent%',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  _gradeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildSmallStat('Produce', widget.produce, Icons.eco_rounded, AppTheme.forestGreen),
              const SizedBox(height: 10),
              _buildSmallStat('Quality', _gradeLabel == 'EXCELLENT' ? 'Tier 1' : 'Tier 2', Icons.workspace_premium_rounded, AppTheme.forestGreen),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _buildSmallStat('Revenue', '₹1,240', Icons.trending_up_rounded, AppTheme.sunsetOrange),
              const SizedBox(height: 10),
              _buildSmallStat('AI Route', 'Yes ✓', Icons.route_rounded, AppTheme.infoBlue),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildSmallStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(42);

  _CelebrationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.1) return;

    final colors = [
      AppTheme.forestGreen,
      AppTheme.sunsetOrange,
      AppTheme.sunsetOrangeLight,
      AppTheme.forestGreenLight,
      AppTheme.infoBlue,
    ];

    for (int i = 0; i < 30; i++) {
      final startX = _random.nextDouble() * size.width;
      final startY = -20.0;
      final endY = size.height * (0.3 + _random.nextDouble() * 0.7);

      final currentY = startY + (endY - startY) * progress;
      final wobble = sin(progress * 6 + i) * 20;

      final opacity = (1.0 - progress).clamp(0.0, 0.6);

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final particleSize = 3.0 + _random.nextDouble() * 4;
      canvas.drawCircle(
        Offset(startX + wobble, currentY),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) => true;
}

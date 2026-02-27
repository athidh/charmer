import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Toggleable debug sidebar showing live technical metrics for judges.
class DebugMetricsPanel extends StatelessWidget {
  final int latencyMs;
  final double infoDensity;
  final double phoneticAccuracy;
  final String pipelineStage;
  final VoidCallback onClose;

  const DebugMetricsPanel({
    super.key,
    required this.latencyMs,
    required this.infoDensity,
    required this.phoneticAccuracy,
    required this.pipelineStage,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1225) : const Color(0xFFF5F0FF),
        border: Border(
          left: BorderSide(
            color: AppTheme.voicePurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    size: 18,
                    color: AppTheme.voicePurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Technical Metrics',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.voicePurple,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            Divider(
              color: AppTheme.voicePurple.withValues(alpha: 0.15),
              height: 1,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Pipeline Stage ──
                  _MetricTile(
                    icon: Icons.route_rounded,
                    label: 'Pipeline Stage',
                    value: pipelineStage,
                    color: _stageColor(pipelineStage),
                  ),
                  const SizedBox(height: 16),

                  // ── Inference Latency ──
                  _MetricTile(
                    icon: Icons.speed_rounded,
                    label: 'Inference Latency',
                    value: '${latencyMs}ms',
                    color: latencyMs < 3000
                        ? AppTheme.successGreen
                        : latencyMs < 5000
                        ? AppTheme.warningAmber
                        : AppTheme.errorRed,
                  ),
                  const SizedBox(height: 4),
                  _buildLatencyBar(latencyMs),
                  const SizedBox(height: 16),

                  // ── Information Density ──
                  _MetricTile(
                    icon: Icons.data_usage_rounded,
                    label: 'Info Density Score',
                    value: infoDensity.toStringAsFixed(2),
                    color: AppTheme.skyClimate,
                  ),
                  const SizedBox(height: 4),
                  _buildProgressBar(infoDensity / 1.0, AppTheme.skyClimate),
                  const SizedBox(height: 16),

                  // ── Phonetic Accuracy ──
                  _MetricTile(
                    icon: Icons.record_voice_over_rounded,
                    label: 'Phonetic Accuracy',
                    value: '${phoneticAccuracy.toStringAsFixed(1)}%',
                    color: phoneticAccuracy > 80
                        ? AppTheme.successGreen
                        : phoneticAccuracy > 60
                        ? AppTheme.warningAmber
                        : AppTheme.errorRed,
                  ),
                  const SizedBox(height: 4),
                  _buildProgressBar(
                    phoneticAccuracy / 100,
                    phoneticAccuracy > 80
                        ? AppTheme.successGreen
                        : phoneticAccuracy > 60
                        ? AppTheme.warningAmber
                        : AppTheme.errorRed,
                  ),
                  const SizedBox(height: 24),

                  // ── 3-Second Target ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          (latencyMs > 0 && latencyMs <= 3000
                                  ? AppTheme.successGreen
                                  : AppTheme.warningAmber)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (latencyMs > 0 && latencyMs <= 3000
                                    ? AppTheme.successGreen
                                    : AppTheme.warningAmber)
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          latencyMs > 0 && latencyMs <= 3000
                              ? Icons.check_circle_rounded
                              : Icons.timer_rounded,
                          size: 16,
                          color: latencyMs > 0 && latencyMs <= 3000
                              ? AppTheme.successGreen
                              : AppTheme.warningAmber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            latencyMs > 0 && latencyMs <= 3000
                                ? '3s Target: MET ✓'
                                : '3s Target: ${latencyMs > 0 ? "OVER" : "Waiting"}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: latencyMs > 0 && latencyMs <= 3000
                                  ? AppTheme.successGreen
                                  : AppTheme.warningAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).moveX(begin: 30, end: 0);
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'STT':
        return AppTheme.warningAmber;
      case 'STT → LLM':
        return AppTheme.skyClimate;
      case 'LLM → TTS':
        return AppTheme.voicePurple;
      case 'Complete':
        return AppTheme.successGreen;
      case 'Error':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildLatencyBar(int ms) {
    final fraction = (ms / 5000).clamp(0.0, 1.0);
    return _buildProgressBar(
      fraction,
      ms < 3000
          ? AppTheme.successGreen
          : ms < 5000
          ? AppTheme.warningAmber
          : AppTheme.errorRed,
    );
  }

  Widget _buildProgressBar(double fraction, Color color) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

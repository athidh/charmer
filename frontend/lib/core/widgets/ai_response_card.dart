import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Reusable AI response card with "Why this?" expandable section, risk indicators,
/// and source citations.
class AiResponseCard extends StatefulWidget {
  final String text;
  final String? explanation;
  final dynamic risks; // List<Map> or null
  final dynamic sources; // List<String> or null

  const AiResponseCard({
    super.key,
    required this.text,
    this.explanation,
    this.risks,
    this.sources,
  });

  @override
  State<AiResponseCard> createState() => _AiResponseCardState();
}

class _AiResponseCardState extends State<AiResponseCard> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 48),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.forestGreen.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Response text ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 14,
                    color: AppTheme.forestGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.text,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Risk indicators ──
          if (widget.risks != null &&
              widget.risks is List &&
              (widget.risks as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (widget.risks as List).map<Widget>((risk) {
                  final severity = risk['severity'] ?? 'low';
                  final color = severity == 'high'
                      ? AppTheme.errorRed
                      : severity == 'medium'
                      ? AppTheme.warningAmber
                      : AppTheme.successGreen;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          risk['label'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── "Why this?" expandable ──
          if (widget.explanation != null && widget.explanation!.isNotEmpty)
            Column(
              children: [
                InkWell(
                  onTap: () =>
                      setState(() => _showExplanation = !_showExplanation),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showExplanation
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 16,
                          color: AppTheme.skyClimate,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Why this recommendation?',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.skyClimate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showExplanation)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.skyClimate.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.explanation!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        height: 1.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ).animate().fadeIn(duration: 200.ms),
              ],
            ),

          // ── Source citations ──
          if (widget.sources != null &&
              widget.sources is List &&
              (widget.sources as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Wrap(
                spacing: 6,
                children: (widget.sources as List).map<Widget>((src) {
                  return Text(
                    '📋 $src',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  );
                }).toList(),
              ),
            ),

          // Bottom padding if nothing else
          if (widget.explanation == null && widget.sources == null)
            const SizedBox(height: 6),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).moveX(begin: -20, end: 0);
  }
}

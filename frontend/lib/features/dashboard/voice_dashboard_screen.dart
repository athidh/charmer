import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../core/services/audio_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/locale_provider.dart';
import '../../core/widgets/ai_response_card.dart';
import '../../core/widgets/debug_metrics_panel.dart';
import '../../l10n/app_localizations.dart';

class VoiceDashboardScreen extends StatefulWidget {
  const VoiceDashboardScreen({super.key});

  @override
  State<VoiceDashboardScreen> createState() => _VoiceDashboardScreenState();
}

class _VoiceDashboardScreenState extends State<VoiceDashboardScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _showDebugPanel = false;
  String _currentStage = 'idle'; // idle, listening, processing, speaking

  // Debug metrics
  int _inferenceLatencyMs = 0;
  double _infoDensityScore = 0.0;
  double _phoneticAccuracy = 0.0;
  String _pipelineStage = '—';

  // Conversation history
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _recorder.dispose();

    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/charmer_recording.wav';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _currentStage = 'listening';
          _pipelineStage = 'STT';
        });
        _rippleController.repeat();
      }
    } catch (e) {
      _showError('Microphone access required');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      _rippleController.stop();
      _rippleController.reset();

      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _currentStage = 'processing';
        _pipelineStage = 'STT → LLM';
      });

      if (path != null) {
        final file = File(path);
        final bytes = await file.readAsBytes();
        await _processVoiceQuery(bytes);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _currentStage = 'idle';
      });
    }
  }

  Future<void> _processVoiceQuery(Uint8List audioBytes) async {
    final stopwatch = Stopwatch()..start();
    try {
      final locale = context.read<LocaleProvider>().locale.languageCode;
      final auth = context.read<AuthProvider>();

      // Stream NDJSON: Phase 1 (transcript) arrives first, Phase 2 (full result) later
      await for (final chunk in auth.api.voiceQueryStream(audioBytes, locale)) {
        if (!mounted) return;

        if (chunk['phase'] == 'stt') {
          // ── Phase 1: Show transcript immediately ──
          setState(() {
            _pipelineStage = 'Processing Recommendation…';
            _phoneticAccuracy =
                (chunk['phonetic_accuracy'] as num?)?.toDouble() ?? 0.0;

            // Add farmer's transcript as a message right away
            _messages.add({
              'role': 'user',
              'text': chunk['transcript'] ?? '...',
              'timestamp': DateTime.now().toIso8601String(),
            });
          });

          // Auto-scroll to show transcript
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else if (chunk['phase'] == 'complete') {
          // ── Phase 2: Full result with AI response + audio ──
          stopwatch.stop();
          setState(() {
            _inferenceLatencyMs = stopwatch.elapsedMilliseconds;
            _infoDensityScore =
                (chunk['info_density'] as num?)?.toDouble() ?? 0.0;
            _phoneticAccuracy =
                (chunk['phonetic_accuracy'] as num?)?.toDouble() ?? 0.0;
            _pipelineStage = 'Complete';
            _currentStage = 'speaking';

            // Add AI response
            _messages.add({
              'role': 'assistant',
              'text': chunk['response'] ?? 'No response',
              'explanation': chunk['explanation'],
              'risks': chunk['hidden_risks'],
              'sources': chunk['sources'],
              'timestamp': DateTime.now().toIso8601String(),
            });

            _isProcessing = false;
          });

          // Auto-scroll to latest message
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          // Play audio response if available
          if (chunk['audio_base64'] != null &&
              chunk['audio_base64'].toString().isNotEmpty) {
            final audioProvider = context.read<AudioProvider>();
            final played = await audioProvider.playBase64Audio(
              chunk['audio_base64'],
            );
            if (!played) {
              debugPrint(
                '🔇 Audio playback failed: ${audioProvider.lastError}',
              );
            }
          }

          setState(() => _currentStage = 'idle');
        }
      }
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _currentStage = 'idle';
        _inferenceLatencyMs = stopwatch.elapsedMilliseconds;
        _pipelineStage = 'Error';
      });
      _showError(
        'Voice query failed: ${e.toString().length > 60 ? e.toString().substring(0, 60) : e}',
      );
    }
  }

  Future<void> _uploadPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null && file.path == null) return;

      setState(() {
        _isProcessing = true;
        _pipelineStage = 'PDF → LLM';
      });

      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final locale = context.read<LocaleProvider>().locale.languageCode;
      final auth = context.read<AuthProvider>();
      final response = await auth.api.analyzePdf(bytes, file.name, locale);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _pipelineStage = 'Complete';

        _messages.add({
          'role': 'system',
          'text': '📄 Analyzed: ${file.name}',
          'timestamp': DateTime.now().toIso8601String(),
        });

        _messages.add({
          'role': 'assistant',
          'text': response['summary'] ?? 'Analysis complete',
          'explanation': response['explanation'],
          'risks': response['hidden_risks'],
          'sources': response['sources'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _pipelineStage = 'Error';
      });
      _showError('PDF analysis failed');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Main content ──
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                _buildTopBar(l, isDark),
                const SizedBox(height: 8),

                // ── Quick action chips ──
                _buildQuickActions(l),
                const SizedBox(height: 8),

                // ── Conversation area ──
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState(l)
                      : _buildConversationList(l),
                ),

                // ── Voice input area ──
                _buildVoiceArea(l, isDark),
              ],
            ),
          ),

          // ── Debug panel overlay ──
          if (_showDebugPanel)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: DebugMetricsPanel(
                latencyMs: _inferenceLatencyMs,
                infoDensity: _infoDensityScore,
                phoneticAccuracy: _phoneticAccuracy,
                pipelineStage: _pipelineStage,
                onClose: () => setState(() => _showDebugPanel = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'CHAR',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                      TextSpan(
                        text: 'MER',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppTheme.riceGold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l.app_tagline,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Debug toggle
          GestureDetector(
            onTap: () => setState(() => _showDebugPanel = !_showDebugPanel),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _showDebugPanel
                    ? AppTheme.voicePurple.withValues(alpha: 0.15)
                    : (isDark ? Colors.white12 : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 20,
                color: _showDebugPanel
                    ? AppTheme.voicePurple
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // PDF upload
          GestureDetector(
            onTap: _isProcessing ? null : _uploadPdf,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l) {
    final chips = [
      {
        'label': l.soil_health,
        'icon': Icons.eco_rounded,
        'color': AppTheme.forestGreen,
      },
      {
        'label': l.fertilizer_ratio,
        'icon': Icons.science_rounded,
        'color': AppTheme.skyClimate,
      },
      {
        'label': l.weather_forecast,
        'icon': Icons.cloud_rounded,
        'color': AppTheme.infoBlue,
      },
      {
        'label': l.crop_advisory,
        'icon': Icons.grass_rounded,
        'color': AppTheme.riceGold,
      },
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          return ActionChip(
            avatar: Icon(
              chip['icon'] as IconData,
              size: 16,
              color: chip['color'] as Color,
            ),
            label: Text(
              chip['label'] as String,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: (chip['color'] as Color).withValues(alpha: 0.3),
            ),
            onPressed: () {},
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none_rounded,
            size: 64,
            color: AppTheme.forestGreen.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            l.voice_hint,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildConversationList(AppLocalizations l) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        if (msg['role'] == 'user') {
          return _buildUserBubble(msg);
        } else if (msg['role'] == 'system') {
          return _buildSystemBubble(msg);
        } else {
          return AiResponseCard(
            text: msg['text'] ?? '',
            explanation: msg['explanation'],
            risks: msg['risks'],
            sources: msg['sources'],
          );
        }
      },
    );
  }

  Widget _buildUserBubble(Map<String, dynamic> msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 14, color: Colors.white70),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                msg['text'] ?? '',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).moveX(begin: 20, end: 0);
  }

  Widget _buildSystemBubble(Map<String, dynamic> msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.skyClimate.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg['text'] ?? '',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.skyClimate,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildVoiceArea(AppLocalizations l, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _currentStage == 'listening'
                  ? l.listening
                  : _currentStage == 'processing'
                  ? l.processing
                  : _currentStage == 'speaking'
                  ? l.speaking
                  : l.press_to_speak,
              key: ValueKey(_currentStage),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isRecording
                    ? AppTheme.errorRed
                    : _isProcessing
                    ? AppTheme.skyClimate
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Pulsating mic button ──
          Stack(
            alignment: Alignment.center,
            children: [
              // Ripple rings during recording
              if (_isRecording) ...[
                for (int i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, _) {
                      final delay = i * 0.3;
                      final progress =
                          ((_rippleController.value + delay) % 1.0);
                      return Container(
                        width: 80 + (progress * 60),
                        height: 80 + (progress * 60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.errorRed.withValues(
                              alpha: (1 - progress) * 0.4,
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
              ],

              // Processing spinner
              if (_isProcessing)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.skyClimate.withValues(alpha: 0.5),
                  ),
                ),

              // Main button
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = _isRecording
                      ? 1.0 + (_pulseController.value * 0.08)
                      : 1.0 + (_pulseController.value * 0.03);
                  return Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _toggleRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isRecording
                              ? const LinearGradient(
                                  colors: [
                                    AppTheme.errorRed,
                                    Color(0xFFFF5252),
                                  ],
                                )
                              : AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isRecording
                                          ? AppTheme.errorRed
                                          : AppTheme.forestGreen)
                                      .withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

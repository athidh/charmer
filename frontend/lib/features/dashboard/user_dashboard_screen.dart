import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_provider.dart';
import '../../core/utils/app_settings.dart';
import '../../core/services/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import 'voice_dashboard_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _selectedDistrict = 'coimbatore';

  String _getGreeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.good_morning;
    if (hour < 17) return l.good_afternoon;
    return l.good_evening;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<AppSettings>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = _getGreeting(l);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Top bar ──
              _buildTopBar(greeting, auth.username, l, settings, isDark),
              const SizedBox(height: 28),

              // ── Hero voice card ──
              _buildVoiceHeroCard(l, isDark),
              const SizedBox(height: 24),

              // ── District selector ──
              _buildDistrictSelector(l, isDark),
              const SizedBox(height: 24),

              // ── Quick features grid ──
              _buildFeatureGrid(l, isDark),
              const SizedBox(height: 24),

              // ── Recent conversations ──
              _buildRecentSection(l, isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    String greeting,
    String username,
    AppLocalizations l,
    AppSettings settings,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 2),
              Text(
                l.hi_user(username),
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 200.ms).moveX(begin: -10, end: 0),
            ],
          ),
        ),
        // Theme toggle
        GestureDetector(
          onTap: () => settings.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              settings.isDarkMode
                  ? Icons.wb_sunny_rounded
                  : Icons.nightlight_round,
              size: 20,
              color: settings.isDarkMode ? AppTheme.riceGold : Colors.blueGrey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Language selector
        PopupMenuButton<String>(
          onSelected: (code) {
            context.read<LocaleProvider>().setLocale(Locale(code));
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.translate_rounded,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'en',
              child: Text('🇺🇸 English', style: GoogleFonts.outfit()),
            ),
            PopupMenuItem(
              value: 'ta',
              child: Text('🇮🇳 தமிழ் (Kongu)', style: GoogleFonts.outfit()),
            ),
            PopupMenuItem(
              value: 'ml',
              child: Text('🇮🇳 മലയാളം', style: GoogleFonts.outfit()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceHeroCard(AppLocalizations l, bool isDark) {
    return GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const VoiceDashboardScreen(),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.forestGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Mic icon with glow
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.press_to_speak,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.voice_hint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 500.ms)
        .moveY(begin: 20, end: 0, curve: Curves.easeOut);
  }

  Widget _buildDistrictSelector(AppLocalizations l, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.district,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildDistrictChip('coimbatore', l.coimbatore, '🏔️', isDark),
            const SizedBox(width: 10),
            _buildDistrictChip('kerala', l.kerala, '🌴', isDark),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildDistrictChip(
    String id,
    String label,
    String emoji,
    bool isDark,
  ) {
    final isActive = _selectedDistrict == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDistrict = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.forestGreen
                : (isDark ? Colors.white12 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppTheme.forestGreen
                  : (isDark ? Colors.white24 : Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(AppLocalizations l, bool isDark) {
    final features = [
      {
        'icon': Icons.eco_rounded,
        'label': l.soil_health,
        'color': AppTheme.forestGreen,
        'desc': 'pH, nutrients, moisture',
      },
      {
        'icon': Icons.science_rounded,
        'label': l.fertilizer_ratio,
        'color': AppTheme.skyClimate,
        'desc': 'NPK per acre calc',
      },
      {
        'icon': Icons.cloud_rounded,
        'label': l.weather_forecast,
        'color': AppTheme.infoBlue,
        'desc': 'Micro-climate data',
      },
      {
        'icon': Icons.picture_as_pdf_rounded,
        'label': l.upload_pdf,
        'color': AppTheme.deepSoil,
        'desc': 'Analyze soil reports',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final f = features[i];
        return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceDashboardScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (f['color'] as Color).withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (f['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        f['icon'] as IconData,
                        size: 20,
                        color: f['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      f['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      f['desc'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(delay: (400 + i * 80).ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
      },
    );
  }

  Widget _buildRecentSection(AppLocalizations l, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.recent_conversations,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 10),
              Text(
                l.no_conversations,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/locale_provider.dart';
import '../dashboard/user_dashboard_screen.dart';
import 'animated_showcase_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  bool _obscureLoginPassword = true;

  // Sign Up controllers
  final _signUpUsernameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signUpUsernameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => const UserDashboardScreen(),
        transitionsBuilder: (context, animation, a2, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _handleSignup() async {
    final username = _signUpUsernameController.text.trim();
    final email = _signUpEmailController.text.trim();
    final password = _signUpPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signup(username, email, password);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please login.'),
          backgroundColor: AppTheme.forestGreen,
        ),
      );
      _tabController.animateTo(1);
      _loginEmailController.text = email;
    } else {
      _showError(auth.error ?? 'Signup failed');
    }
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(email, password);

    if (!mounted) return;
    if (success) {
      _navigateToDashboard();
    } else {
      _showError(auth.error ?? 'Invalid credentials');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Full-screen animated video-like background ──
          const Positioned.fill(child: AnimatedShowcaseBackground()),

          // ── Brand badge (top left) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'CHAR',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      TextSpan(
                        text: 'MER',
                        style: GoogleFonts.outfit(
                          color: AppTheme.riceGold,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).moveX(begin: -20, end: 0),
          ),

          // ── Language selector row ──
          Positioned(
            bottom: _getSheetHeight(context) + 16,
            left: 0,
            right: 0,
            child: _buildLanguageSelector(context),
          ),

          // ── Frosted glass bottom sheet ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child:
                ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          height: _getSheetHeight(context),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, -10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              20,
                              24,
                              bottomPadding + 16,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Drag handle
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Tab bar
                                _buildTabBar(l),
                                const SizedBox(height: 20),

                                // Tab content
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildSignUpForm(l),
                                      _buildLoginForm(l),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .moveY(begin: 60, end: 0, curve: Curves.easeOutCubic),
          ),
        ],
      ),
    );
  }

  double _getSheetHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Reduced from 55% to 42% so background video is clearly visible
    return screenHeight * 0.42;
  }

  Widget _buildTabBar(AppLocalizations l) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.forestGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.forestGreen, AppTheme.forestGreenLight],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.forestGreen.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          Tab(text: l.tab_signup),
          Tab(text: l.tab_login),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(AppLocalizations l) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 4),
          _GlassTextField(
            controller: _signUpUsernameController,
            label: l.username_label,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _GlassTextField(
            controller: _signUpEmailController,
            label: l.email_label,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _GlassTextField(
            controller: _signUpPasswordController,
            label: l.password_label,
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscure: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 20),
          _buildPrimaryButton(
            l.create_account_btn,
            Icons.arrow_forward_rounded,
          ),
          const SizedBox(height: 16),
          _buildDividerWithText(l.or_continue_with),
          const SizedBox(height: 16),
          _buildSocialButtons(),
          const SizedBox(height: 14),
          _buildSwitchPrompt(
            l.have_account,
            l.tab_login,
            () => _tabController.animateTo(1),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLoginForm(AppLocalizations l) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            l.welcome_back,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.sign_in_subtitle,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _GlassTextField(
            controller: _loginEmailController,
            label: l.email_label,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _GlassTextField(
            controller: _loginPasswordController,
            label: l.password_label,
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscure: _obscureLoginPassword,
            onToggleObscure: () =>
                setState(() => _obscureLoginPassword = !_obscureLoginPassword),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l.forgot_password,
                style: GoogleFonts.outfit(
                  color: AppTheme.sunsetOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPrimaryButton(l.login_btn, Icons.login_rounded),
          const SizedBox(height: 16),
          _buildDividerWithText(l.or_continue_with),
          const SizedBox(height: 16),
          _buildSocialButtons(),
          const SizedBox(height: 14),
          _buildSwitchPrompt(
            l.no_account,
            l.tab_signup,
            () => _tabController.animateTo(0),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon) {
    final auth = context.watch<AuthProvider>();
    final isLogin = _tabController.index == 1;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestGreen.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: auth.isLoading
            ? null
            : (isLogin ? _handleLogin : _handleSignup),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: auth.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: Colors.white),
                ],
              ),
      ),
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.25))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.25))),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(Icons.g_mobiledata_rounded, 'Google'),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildSocialButton(Icons.apple_rounded, 'Apple')),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        minimumSize: const Size(0, 44),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildSwitchPrompt(String prefix, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prefix,
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: GoogleFonts.outfit(
              color: AppTheme.forestGreen,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Language selector (extension on _AuthScreenState) ──

extension _LanguageSelector on _AuthScreenState {
  static const _langs = [
    {'code': 'en', 'label': 'EN', 'flag': '🇺🇸'},
    {'code': 'ta', 'label': 'த', 'flag': '🇮🇳'},
    {'code': 'ml', 'label': 'മ', 'flag': '🇮🇳'},
  ];

  Widget _buildLanguageSelector(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    final current = provider.locale.languageCode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _langs.map((lang) {
        final isActive = current == lang['code'];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => provider.setLocale(Locale(lang['code']!)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppTheme.forestGreen
                      : Colors.white.withValues(alpha: 0.3),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.forestGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang['flag']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    lang['label']!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppTheme.forestGreen : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 300.ms).moveY(begin: 10, end: 0);
  }
}
// ── Premium glass text field ──

class _GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.obscure = false,
    this.onToggleObscure,
  });

  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppTheme.forestGreen.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.isPassword ? widget.obscure : false,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused ? AppTheme.forestGreen : AppTheme.textSecondary,
            size: 20,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    widget.obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: widget.onToggleObscure,
                )
              : null,
          labelText: widget.label,
          labelStyle: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
          floatingLabelStyle: GoogleFonts.outfit(
            color: AppTheme.forestGreen,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.forestGreen, width: 2),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade50,
        ),
      ),
    );
  }
}

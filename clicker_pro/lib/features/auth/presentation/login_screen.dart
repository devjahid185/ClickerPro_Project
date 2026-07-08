// lib/features/auth/presentation/login_screen.dart
//
// Clicker Pro — Login Screen v2 (Dark Luxury Lens)
//
// Visual: PRESERVED 1:1 from the v2 design (the "gold standard" in the spec).
// Wiring: refactored to ConsumerStatefulWidget that talks to:
//   • sessionControllerProvider     — login + post-login state
//   • languageControllerProvider    — read/write active locale
//
// Routes from this screen:
//   • Forgot Password?       → ForgotPasswordScreen   (slide-from-right, 280ms, Cubic(0.2, 0.8, 0.2, 1))
//   • Register Now           → RegisterScreen          (same slide)
//   • I have an invite code  → ManagerInviteScreen     (same slide)
//
// Animation tokens used app-wide (also reused on the other auth screens):
//   • Page slide-in : Cubic(0.2, 0.8, 0.2, 1) over 280ms
//   • Page slide-out: Curves.easeIn over 200ms

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/env/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/providers.dart';
import '../../../core/storage/kv_store.dart';
import '../../../screens/dashboard_screen.dart';
import '../../../shared/widgets/auth_glass_field.dart';
import '../../../shared/widgets/clicker_logo.dart';
import '../../../shared/widgets/video_backdrop.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../settings/application/language_controller.dart';
import '../application/session_controller.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Slide-from-right page route shared by every auth-screen transition.
/// Cubic-bezier(0.2, 0.8, 0.2, 1) over 280ms in / 200ms out.
PageRouteBuilder<T> slideFromRightRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) {
      final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: anim,
              curve: const Cubic(0.2, 0.8, 0.2, 1),
              reverseCurve: Curves.easeIn,
            ),
          );
      final fade = CurvedAnimation(
        parent: anim,
        curve: const Cubic(0.2, 0.8, 0.2, 1),
        reverseCurve: Curves.easeIn,
      );
      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: fade, child: child),
      );
    },
  );
}

/// Social sign-in is live: the backend verifies Google/Apple ID tokens
/// at /api/auth/google and /api/auth/apple. NOTE: Google sign-in on a
/// device additionally needs the app's SHA fingerprints registered in
/// Firebase (Authentication → Google enabled) and a refreshed
/// google-services.json — see the deploy notes.
const bool kSocialLoginEnabled = true;

/// Web login backdrop artwork. On the web the looping brand video is skipped
/// (autoplay is unreliable and the clip is heavy to ship), so a still hero
/// image is used instead. Drop the artwork at this exact path — the folder
/// `assets/Login/` is already declared in pubspec, so no manifest change is
/// needed. Until the file exists the backdrop falls back to solid black.
const String kWebLoginImage = 'assets/Login/login_web_bg.jpg';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _appleLoading = false;
  DateTime? _pendingDeleteUntil;

  // ─── Error shake (Task 20.7 / MOD-06) ───────────────────────────
  // Form translates ±6px over 360ms on auth/network errors.
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));
    _loadPendingDeletion();
  }

  Future<void> _loadPendingDeletion() async {
    final raw = await ref
        .read(kvStoreProvider)
        .readString(KvKeys.pendingDeleteUntil);
    if (!mounted || raw == null) return;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      setState(() => _pendingDeleteUntil = parsed);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // SessionController.login() uses AsyncValue.guard, so it never throws —
    // a failed login lands in the provider's error state instead. We must
    // inspect that state after awaiting, not rely on a try/catch.
    await ref
        .read(sessionControllerProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    final session = ref.read(sessionControllerProvider);

    // Success only when we actually have a session value.
    if (session.hasValue && session.value != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: RouteNames.dashboard),
          builder: (_) => const DashboardScreen(),
        ),
        (route) => false,
      );
      return;
    }

    // Otherwise surface why it failed — by status code, not by string
    // matching, so 429 (rate limit) and 403 (disabled) get honest messages.
    final error = session.error;
    final String msg;
    if (error is ApiException) {
      if (error.isUnauthorized) {
        msg = 'Wrong email or password.';
      } else if (error.isRateLimited) {
        msg = 'Too many attempts — wait 1 minute and try again.';
      } else if (error.statusCode == 403) {
        msg = 'This account is disabled. Please contact support.';
      } else if (error.isNetwork) {
        msg = 'Cannot reach the server. Check your internet.';
      } else {
        msg = 'Login failed (${error.statusCode}). Please try again.';
      }
    } else {
      msg = 'Login failed. Please try again.';
    }
    _showError(msg);
  }

  void _handleForgotPassword() {
    Navigator.of(
      context,
    ).push(slideFromRightRoute(const ForgotPasswordScreen()));
  }

  void _handleRegister() {
    Navigator.of(context).push(slideFromRightRoute(const RegisterScreen()));
  }


  Future<void> _handleAppleSignIn() async {
    setState(() => _appleLoading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('No identity token');

      await ref
          .read(sessionControllerProvider.notifier)
          .loginWithApple(idToken);

      if (!mounted) return;
      final session = ref.read(sessionControllerProvider);
      if (session.hasValue && session.value != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
        return;
      }
      _showError('Apple sign-in failed. Please try again.');
    } catch (_) {
      if (mounted) _showError('Apple sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) _shakeCtrl.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: AppColors.film, fontSize: 13),
        ),
        backgroundColor: AppColors.voidElevated,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the language so headers/labels rebuild when it changes.
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');
    String t(String key) => AppStrings.get(key, lang);

    return Scaffold(
      // Full-bleed video backdrop → the scaffold sits on black so there is no
      // paper-coloured seam behind the video / status bar.
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─── FULL-SCREEN BRAND BACKDROP ──────────────────────────
          // Mobile: a looping, muted ambient clip. Web: a still hero image
          // (see [kWebLoginImage]). Either way a dark gradient scrim keeps the
          // wordmark + form legible over it.
          const Positioned.fill(child: _LoginBackdrop()),

          // ─── MAIN CONTENT ────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: AnimatedBuilder(
                    animation: _shake,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(_shake.value, 0),
                      child: child,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // ── BRAND LOGO ─────────────────────────────
                        _buildBrandLogo(),
                        const SizedBox(height: 32),

                        // ── HEADLINE ───────────────────────────────
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            // ClickerPro wordmark (spec): Hanken 800, tight
                            // tracking, "Pro" in brand orange — NOT italic.
                            style: TextStyle(
                              fontFamily: AppText.clickerBrandFontFamily,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              // Over the dark video scrim the wordmark is white.
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -0.04 * 34,
                            ),
                            children: [
                              TextSpan(text: 'Clicker'),
                              TextSpan(
                                text: 'Pro',
                                style: TextStyle(color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'COMPANY MANAGEMENT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppText.bodyFontFamily,
                            fontSize: 10.5,
                            letterSpacing: 2.5,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 40),

                        if (_pendingDeleteUntil != null) ...[
                          _buildPendingDeleteBanner(_pendingDeleteUntil!),
                          const SizedBox(height: 18),
                        ],

                        // ── EMAIL FIELD ────────────────────────────
                        AuthGlassField(
                          controller: _emailController,
                          label: t('email'),
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Enter email" : null,
                        ),
                        const SizedBox(height: 16),

                        // ── PASSWORD FIELD ─────────────────────────
                        AuthGlassField(
                          controller: _passwordController,
                          label: t('password'),
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscured: _obscurePassword,
                          onToggleObscure: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          textInputAction: TextInputAction.done,
                          validator: (v) => v == null || v.isEmpty
                              ? "Enter password"
                              : null,
                        ),

                        // ── FORGOT PASSWORD ────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _handleForgotPassword,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                child: Text(
                                  t('forgot_password'),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── LOGIN BUTTON (premium gradient) ────────
                        _buildLoginButton(t('login')),

                        const SizedBox(height: 24),

                        // ── DIVIDER + SOCIAL LOGIN ────────────────
                        // Google sign-in removed per product decision. The
                        // only remaining social option is Apple, which exists
                        // on iOS alone — so on Android this whole block is
                        // hidden (no lonely "OR" divider).
                        if (kSocialLoginEnabled &&
                            defaultTargetPlatform == TargetPlatform.iOS) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontFamily: AppText.bodyFontFamily,
                                    fontSize: 9.5,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _SocialButton(
                            label: 'Continue with Apple',
                            icon: _kAppleIcon,
                            loading: _appleLoading,
                            onTap: _handleAppleSignIn,
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── REGISTER LINK ─────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${t('no_account')} ",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: _handleRegister,
                              child: Text(
                                t('create_account'),
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Invite-code entry and the language switch moved
                        // out of login per design feedback — managers join
                        // from Register, language lives in Settings.

                        // ── COMPANY BRANDING ──────────────────────
                        const SizedBox(height: 18),
                        Text(
                          '${AppConfig.appName} ${AppConfig.appVersionLabel} · by ${AppConfig.companyName}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 10,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BRAND LOGO (blade-fan hero mark) ──────────────────────────
  Widget _buildBrandLogo() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo so the fan floats over the page like the landing hero.
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.08),
            ),
          ),
          const ClickerLogo(size: 88),
        ],
      ),
    );
  }

  // ─── PENDING-DELETE BANNER ─────────────────────────────────────
  Widget _buildPendingDeleteBanner(DateTime until) {
    final dateLabel =
        '${until.year}-${until.month.toString().padLeft(2, '0')}-${until.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded, color: AppColors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your account is scheduled for deletion on $dateLabel.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to cancel',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOGIN BUTTON ──────────────────────────────────────────────
  Widget _buildLoginButton(String label) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.accent,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: _isLoading
                ? SizedBox(
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
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Login backdrop (video on mobile, still image on web) ──────────────────
class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  // Dark gradient scrim shared by both treatments — darker at the top and
  // bottom edges (behind the wordmark and footer) and lighter through the
  // middle so the artwork still reads behind the glass form.
  static const _scrim = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x8C000000), Color(0x59000000), Color(0xB3000000)],
        stops: [0.0, 0.45, 1.0],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            kWebLoginImage,
            fit: BoxFit.cover,
            // Degrade to solid black (never a broken-image glyph) until the
            // artwork file is dropped into assets/Login/.
            errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
          ),
          const Positioned.fill(child: _scrim),
        ],
      );
    }
    return const VideoBackdrop(
      asset: 'assets/Login/Login.mp4',
      fallbackColor: Colors.black,
      scrim: _scrim,
    );
  }
}

// ─── Apple icon ───────────────────────────────────────────────────────────
const _kAppleIcon = _AppleIcon();

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.apple, size: 22, color: AppColors.film);
  }
}

// ─── Social button ────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.voidElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/env/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/storage/kv_store.dart';
import '../../../screens/dashboard_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../settings/application/language_controller.dart';
import '../application/session_controller.dart';
import 'forgot_password_screen.dart';
import 'manager_invite_screen.dart';
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

/// The Laravel backend has no `/api/auth/google` / `/api/auth/apple`
/// routes yet, so the social buttons would always fail with a 404.
/// Hidden until the backend endpoints exist — flip this to re-enable.
const bool kSocialLoginEnabled = false;

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
  bool _googleLoading = false;
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
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
        msg = 'ইমেইল বা পাসওয়ার্ড ভুল।';
      } else if (error.isRateLimited) {
        msg = 'অনেকবার চেষ্টা হয়েছে — ১ মিনিট অপেক্ষা করে আবার চেষ্টা করুন।';
      } else if (error.statusCode == 403) {
        msg = 'অ্যাকাউন্টটি নিষ্ক্রিয় করা আছে। সাপোর্টে যোগাযোগ করুন।';
      } else if (error.isNetwork) {
        msg = 'সার্ভারের সাথে যোগাযোগ করা যাচ্ছে না। ইন্টারনেট চেক করুন।';
      } else {
        msg = 'লগইন ব্যর্থ হয়েছে (${error.statusCode})। আবার চেষ্টা করুন।';
      }
    } else {
      msg = 'লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';
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

  void _handleInvite() {
    Navigator.of(
      context,
    ).push(slideFromRightRoute(const ManagerInviteScreen()));
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _googleLoading = false);
        return;
      }
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('No ID token');

      await ref
          .read(sessionControllerProvider.notifier)
          .loginWithGoogle(idToken);

      if (!mounted) return;
      final session = ref.read(sessionControllerProvider);
      if (session.hasValue && session.value != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
        return;
      }
      _showError('Google sign-in failed. Please try again.');
    } catch (_) {
      if (mounted) _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
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
          style: const TextStyle(color: AppColors.film, fontSize: 13),
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
      backgroundColor: AppColors.voidBlack,
      body: Stack(
        children: [
          // ─── WATERMARK LOGO (subtle brand backdrop) ───────────────
          // Very low opacity + IgnorePointer: pure branding, never
          // interferes with touch targets or readability.
          Positioned(
            right: -70,
            bottom: -50,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.045,
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 340,
                  color: AppColors.film,
                ),
              ),
            ),
          ),
          // ─── BACKGROUND GLOW BLOBS ────────────────────────────────
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
            ),
          ),

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
                            style: TextStyle(
                              fontFamily: AppText.brand.fontFamily,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: AppColors.film,
                              height: 1.1,
                            ),
                            children: [
                              TextSpan(text: 'Clicker '),
                              TextSpan(
                                text: 'Pro',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang == 'bn'
                              ? 'কোম্পানি ম্যানেজমেন্ট'
                              : 'COMPANY MANAGEMENT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10.5,
                            letterSpacing: 2.5,
                            color: AppColors.filmDim.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 40),

                        if (_pendingDeleteUntil != null) ...[
                          _buildPendingDeleteBanner(_pendingDeleteUntil!),
                          const SizedBox(height: 18),
                        ],

                        // ── EMAIL FIELD ────────────────────────────
                        _glassField(
                          controller: _emailController,
                          label: t('email'),
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v == null || v.isEmpty ? "ইমেইল লিখুন" : null,
                        ),
                        const SizedBox(height: 14),

                        // ── PASSWORD FIELD ─────────────────────────
                        _glassField(
                          controller: _passwordController,
                          label: t('password'),
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: (v) => v == null || v.isEmpty
                              ? "পাসওয়ার্ড লিখুন"
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
                                  style: const TextStyle(
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
                        // Hidden while kSocialLoginEnabled is false (no
                        // backend routes yet — see the constant's doc).
                        if (kSocialLoginEnabled) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  lang == 'bn' ? 'অথবা' : 'OR',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 9.5,
                                    letterSpacing: 1.5,
                                    color: AppColors.filmDim.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _SocialButton(
                            label: lang == 'bn'
                                ? 'Google দিয়ে লগইন'
                                : 'Continue with Google',
                            icon: _kGoogleIcon,
                            loading: _googleLoading,
                            onTap: _handleGoogleSignIn,
                          ),
                          const SizedBox(height: 10),
                          _SocialButton(
                            label: lang == 'bn'
                                ? 'Apple দিয়ে লগইন'
                                : 'Continue with Apple',
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
                                color: AppColors.filmDim.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: _handleRegister,
                              child: Text(
                                t('create_account'),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── INVITE-CODE LINK (Manager onboarding) ─
                        Center(
                          child: GestureDetector(
                            onTap: _handleInvite,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Text(
                                lang == 'bn'
                                    ? 'আমার একটি ইনভাইট কোড আছে'
                                    : 'I have an invite code',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  color: AppColors.gold.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── LANGUAGE SWITCH ───────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final newLang = lang == 'en' ? 'bn' : 'en';
                              await ref
                                  .read(languageControllerProvider.notifier)
                                  .setLanguage(newLang);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.language_rounded,
                                    size: 14,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    lang == 'en'
                                        ? "বাংলায় দেখুন"
                                        : "Switch to English",
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── COMPANY BRANDING ──────────────────────
                        const SizedBox(height: 14),
                        Text(
                          '${AppConfig.appName} ${AppConfig.appVersionLabel} · by ${AppConfig.companyName}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.filmMuted.withValues(alpha: 0.7),
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

  // ─── BRAND LOGO (camera in luxury circle) ──────────────────────
  Widget _buildBrandLogo() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.18),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 28,
              color: AppColors.accent,
            ),
          ),
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
          const Icon(Icons.schedule_rounded, color: AppColors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your account is scheduled for deletion on $dateLabel.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
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

  // ─── GLASS INPUT FIELD ─────────────────────────────────────────
  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.film,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.7),
            fontSize: 13.5,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.accent,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: AppColors.accent, size: 19),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.filmDim,
                    size: 19,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          errorStyle: const TextStyle(
            color: Colors.redAccent,
            fontSize: 11,
            height: 0.8,
          ),
        ),
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
                        label,
                        style: const TextStyle(
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

// ─── Google SVG path (G mark) ─────────────────────────────────────────────
const _kGoogleIcon = _GoogleIcon();
const _kAppleIcon = _AppleIcon();

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Blue
    canvas.drawArc(
      Rect.fromLTWH(0, 0, s, s),
      -1.05,
      2.1,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.18,
    );
    // Red
    canvas.drawArc(
      Rect.fromLTWH(0, 0, s, s),
      1.05,
      2.3,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.18,
    );
    // Yellow
    canvas.drawArc(
      Rect.fromLTWH(0, 0, s, s),
      3.35,
      0.75,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.18,
    );
    // Green
    canvas.drawArc(
      Rect.fromLTWH(0, 0, s, s),
      4.1,
      0.9,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.18,
    );
    // Horizontal bar
    final paint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = s * 0.18
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s * 0.5, s * 0.5),
      Offset(s * 0.95, s * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.apple, size: 22, color: AppColors.film);
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
            ? const Center(
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
                    style: const TextStyle(
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

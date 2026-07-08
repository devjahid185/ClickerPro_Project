// lib/features/auth/presentation/register_screen.dart
//
// Clicker Pro — Register Screen (Dark Luxury Lens)
//
// Visual: matches LoginScreen 1:1 — Void Black background, ambient blobs,
// camera-in-luxury-circle brand mark, Cormorant Garamond headline,
// glass inputs, orange-gradient submit with glow.
//
// Form: Full Name, Email, Phone, Password, Confirm Password, Role pill
// (Owner / Freelancer / Both — Manager goes via the Accept Invite flow per
// Requirement 1.4), and a consent checkbox that gates the submit button.
//
// Wiring: ConsumerStatefulWidget, calls
// `sessionControllerProvider.notifier.register(...)` on submit.
//
// Animations:
//   • Role pill segmented control: orange-tinted indicator slides between
//     segments using AnimatedAlign + AnimatedSwitcher (220ms easeOutCubic).
//   • Submit button: same gradient + glow as Login, with the loading swap.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/validation/phone_validator.dart';
import '../../../shared/widgets/auth_glass_field.dart';
import '../../../shared/widgets/web_shell.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/session_controller.dart';
import '../domain/otp_purpose.dart';
import '../domain/user_role.dart';
import 'otp_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  UserRole _role = UserRole.owner;
  bool _consent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _emailError;

  // Rotating full-screen backdrop: one of these is picked at random each time
  // the Register screen mounts, so different users / sessions see a different
  // photo. A dark gradient scrim over it keeps the (always-white) text crisp
  // no matter how bright or colourful the chosen image is.
  static const List<String> _backdrops = [
    'assets/Register/Register.jpg',
    'assets/Register/Register 2.jpg',
    'assets/Register/Register 3.jpg',
    'assets/Register/Register 4.jpg',
    'assets/Register/Register 5.jpg',
  ];
  late final String _backdrop =
      _backdrops[math.Random().nextInt(_backdrops.length)];

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────
  String? _validateName(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter name';
    if (t.length > 80) return 'Name is too long';
    return null;
  }

  String? _validateCompany(String? v) {
    final needs = _role == UserRole.owner || _role == UserRole.both;
    if (!needs) return null;
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter company name';
    if (t.length > 80) return 'Name is too long';
    return null;
  }

  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter email';
    if (!t.contains('@') || !_emailRegex.hasMatch(t)) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? v) => PhoneValidator.validate(v);

  String? _validatePassword(String? v) {
    final t = v ?? '';
    if (t.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(t)) return 'At least 1 letter required';
    if (!RegExp(r'\d').hasMatch(t)) return 'At least 1 number required';
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '') != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    setState(() => _emailError = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) return;

    setState(() => _isLoading = true);
    try {
      // Registration NO LONGER logs the user in — it just creates the
      // unverified account. The session is minted only after the email OTP
      // is confirmed on the OTP screen. So on success we go straight to OTP.
      await ref
          .read(sessionControllerProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _role,
            companyName: (_role == UserRole.owner || _role == UserRole.both)
                ? _companyController.text.trim()
                : null,
          );

      if (!mounted) return;

      // Fire the 6-digit code (fail-soft — a mail hiccup must not strand the
      // user; they can resend on the OTP screen) and route to OTP. The OTP
      // screen completes the signup and lands on the Dashboard after verify.
      final email = _emailController.text.trim();
      try {
        await ref
            .read(authRepositoryProvider)
            .requestOtp(identifier: email, purpose: OtpPurpose.signup);
      } catch (_) {
        // Code email failed — continue; user can resend from the screen.
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              OtpScreen(identifier: email, purpose: OtpPurpose.signup),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.statusCode == 409) {
        setState(() => _emailError = 'This email is already registered');
      } else {
        _showError(
          e is ApiException ? e.message : 'Could not complete registration.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
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

    return Scaffold(
      // Full-bleed photo backdrop → scaffold on black so there is no paper
      // seam behind the image / status bar.
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─── FULL-SCREEN ROTATING PHOTO ──────────────────────────
          Positioned.fill(
            child: Image.asset(_backdrop, fit: BoxFit.cover),
          ),
          // Dark gradient scrim (stronger top & bottom, where the heading and
          // the CTA / sign-in link sit) so white text reads on any photo.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.62),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ─── MAIN CONTENT ────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: WebFormWidth(
                  child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      _buildBrandLogo(),
                      const SizedBox(height: 26),

                      Text(
                        'Create your\naccount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppText.brand.fontFamily,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          // White over the photo scrim.
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'COMPANY MANAGEMENT · STEP 1 OF 1',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppText.bodyFontFamily,
                          fontSize: 11.5,
                          letterSpacing: 2.2,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 80),
                        height: 1,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── ROLE PILL ──────────────────────────────
                      _RolePill(
                        selected: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),

                      const SizedBox(height: 22),

                      // ── FORM FIELDS ────────────────────────────
                      AuthGlassField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: _validateName,
                        textInputAction: TextInputAction.next,
                      ),
                      // Company name — only Owner / Both must fill this.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child:
                            (_role == UserRole.owner || _role == UserRole.both)
                            ? Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: AuthGlassField(
                                  controller: _companyController,
                                  label: 'Company Name',
                                  icon: Icons.business_rounded,
                                  validator: _validateCompany,
                                  textInputAction: TextInputAction.next,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 14),
                      AuthGlassField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) => _emailError ?? _validateEmail(v),
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      AuthGlassField(
                        controller: _phoneController,
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 14),
                      AuthGlassField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscured: _obscurePassword,
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 14),
                      AuthGlassField(
                        controller: _confirmController,
                        label: 'Confirm Password',
                        icon: Icons.lock_reset_rounded,
                        isPassword: true,
                        obscured: _obscureConfirm,
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        textInputAction: TextInputAction.done,
                        validator: _validateConfirm,
                      ),

                      const SizedBox(height: 18),

                      // ── CONSENT ROW ────────────────────────────
                      _ConsentRow(
                        checked: _consent,
                        onChanged: (v) => setState(() => _consent = v),
                        onTapTerms: () =>
                            Navigator.of(context).pushNamed(RouteNames.terms),
                        onTapPrivacy: () =>
                            Navigator.of(context).pushNamed(RouteNames.privacy),
                      ),

                      const SizedBox(height: 22),

                      _buildSubmitButton(
                        enabled: _consent && !_isLoading,
                        loading: _isLoading,
                      ),

                      const SizedBox(height: 20),

                      // ── BACK TO SIGN-IN ────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
          // ─── BACK BUTTON ─────────────────────────────────────────
          Positioned(
            top: 12,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BRAND LOGO (small camera-in-luxury-circle) ────────────────
  Widget _buildBrandLogo() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange.withValues(alpha: 0.1),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange.withValues(alpha: 0.18),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 24,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SUBMIT BUTTON ─────────────────────────────────────────────
  Widget _buildSubmitButton({required bool enabled, required bool loading}) {
    return AnimatedOpacity(
      opacity: enabled || loading ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 220),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.orange,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: enabled ? _handleSubmit : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: loading
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
                      children: const [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Role pill (3-segment) — orange-filled active, glass inactive,
// indicator slides between segments with AnimatedAlign.
// ─────────────────────────────────────────────────────────────────
class _RolePill extends StatelessWidget {
  const _RolePill({required this.selected, required this.onChanged});

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  static const _segments = <UserRole>[
    UserRole.owner,
    UserRole.freelancer,
    UserRole.both,
    UserRole.officeStaff,
  ];

  String _label(UserRole r) {
    switch (r) {
      case UserRole.owner:
        return 'Company';
      case UserRole.freelancer:
        return 'Freelancer';
      case UserRole.both:
        return 'Both';
      case UserRole.manager:
        return 'Manager';
      case UserRole.officeStaff:
        return 'Staff';
      case UserRole.webAdmin:
        return 'Web Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _segments.indexOf(selected);
    return LayoutBuilder(
      builder: (context, c) {
        final segWidth = c.maxWidth / _segments.length;
        // Indicator alignment from -1.0 (left) to 1.0 (right) across the row.
        final alignmentX = _segments.length == 1
            ? 0.0
            : (index * 2 / (_segments.length - 1)) - 1.0;

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Stack(
            children: [
              // Sliding indicator.
              AnimatedAlign(
                alignment: Alignment(alignmentX, 0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: segWidth - 4,
                  height: 42,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.orange,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Tappable labels.
              Row(
                children: [
                  for (final r in _segments)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(r),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: r == selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              letterSpacing: 0.3,
                              color: r == selected
                                  ? Colors.white
                                  : AppColors.filmDim.withValues(alpha: 0.85),
                            ),
                            child: Text(_label(r)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Consent row with inline tap-to-read links.
// ─────────────────────────────────────────────────────────────────
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.checked,
    required this.onChanged,
    required this.onTapTerms,
    required this.onTapPrivacy,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!checked),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(top: 2, right: 10),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: checked
                  ? AppColors.orange
                  : AppColors.surfaceAlt,
              border: Border.all(
                color: checked ? AppColors.orange : AppColors.gray300,
                width: 1.4,
              ),
            ),
            child: checked
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _TapRecognizer(onTapTerms),
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _TapRecognizer(onTapPrivacy),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Tiny TapGestureRecognizer factory wrapper so RichText spans stay readable.
class _TapRecognizer extends TapGestureRecognizer {
  _TapRecognizer(VoidCallback onTap) {
    this.onTap = onTap;
  }
}

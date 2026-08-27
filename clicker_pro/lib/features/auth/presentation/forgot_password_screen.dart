// lib/features/auth/presentation/forgot_password_screen.dart
//
// Graphy7 — Forgot Password (Dark Luxury Lens)
//
// Single-page flow (no extra screens):
//   1. Enter email ? "Send Reset Code" (backend emails a 6-digit code)
//   2. The code + new-password fields expand BELOW on the same page
//   3. "Reset Password" ? success snackbar ? back to Login
//
// Password must be at least 8 characters (matches backend min:8).
// Always shows a generic acknowledgement on send per Requirement 1.10
// (no account enumeration).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSending = false;
  bool _isResetting = false;
  bool _codeSent = false;
  bool _obscurePassword = true;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter email';
    if (!_emailRegex.hasMatch(t)) return 'Enter a valid email';
    return null;
  }

  Future<void> _handleSend() async {
    if (_validateEmail(_emailController.text) != null) {
      _formKey.currentState!.validate();
      return;
    }
    setState(() => _isSending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
      _showInfo('Code sent — check your email (also check Spam).');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Cannot reach the server.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleReset() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    if (code.length != 6) {
      _showError('Enter the 6-digit code sent to your email.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    setState(() => _isResetting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            token: code,
            newPassword: password,
            email: _emailController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password changed ? — log in with your new password.',
            style: TextStyle(color: AppColors.film, fontSize: 13),
          ),
          backgroundColor: AppColors.voidElevated,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 422) {
        _showError('Code is wrong or expired — tap "Send Reset Code" again.');
      } else {
        _showError(e.message);
      }
    } catch (_) {
      if (!mounted) return;
      _showError('Cannot reach the server.');
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  void _showError(String message) => _showSnack(message, error: true);
  void _showInfo(String message) => _showSnack(message, error: false);

  void _showSnack(String message, {required bool error}) {
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
          side: BorderSide(
            color: error
                ? Colors.redAccent.withValues(alpha: 0.4)
                : AppColors.gold.withValues(alpha: 0.4),
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      body: Stack(
        children: [
          // --- BACKGROUND BLOBS ------------------------------------
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.07),
              ),
            ),
          ),



          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 36),
                      _smallBrandLogo(),
                      const SizedBox(height: 28),
                      Text(
                        'Forgot your\npassword?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppText.bodyFontFamily,
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: AppColors.film,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PASSWORD RECOVERY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppText.bodyFontFamily,
                          fontSize: 10.5,
                          letterSpacing: 2.5,
                          color: AppColors.filmDim.withValues(alpha: 0.7),
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
                      const SizedBox(height: 12),
                      Text(
                        _codeSent
                            ? 'Enter the 6-digit code from your email and a new password below.'
                            : 'Enter your registered email — we will send a reset code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.filmDim.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 32),

                      _glassField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.mail_outline_rounded,
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_codeSent,
                      ),

                      const SizedBox(height: 16),

                      _gradientButton(
                        label: _codeSent ? 'Send Code Again' : 'Send Reset Code',
                        loading: _isSending,
                        filled: !_codeSent,
                        onTap: _isSending ? null : _handleSend,
                      ),

                      // -- CODE + NEW PASSWORD (same page) -----------
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: _codeSent
                            ? Column(
                                children: [
                                  const SizedBox(height: 24),
                                  _glassField(
                                    controller: _codeController,
                                    label: '6-digit Code',
                                    icon: Icons.pin_outlined,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _glassField(
                                    controller: _passwordController,
                                    label: 'New Password (min 8)',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscurePassword,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 18,
                                        color: AppColors.filmDim,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _gradientButton(
                                    label: 'Reset Password',
                                    loading: _isResetting,
                                    filled: true,
                                    onTap: _isResetting ? null : _handleReset,
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // --- BACK BUTTON -----------------------------------------
          Positioned(
            top: 12,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.film,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBrandLogo() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange.withValues(alpha: 0.1),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange.withValues(alpha: 0.18),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.4),
                width: 1.4,
              ),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 22,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscure = false,
    bool enabled = true,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.film.withValues(alpha: 0.08)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        obscureText: obscure,
        enabled: enabled,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(color: AppColors.film, fontSize: 14.5),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.7),
            fontSize: 13.5,
          ),
          floatingLabelStyle: TextStyle(
            color: AppColors.orange,
            fontSize: 13,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: AppColors.orange, size: 19),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.orange.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          errorStyle: TextStyle(
            color: Colors.redAccent,
            fontSize: 11,
            height: 0.9,
          ),
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required bool loading,
    required VoidCallback? onTap,
    bool filled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: filled ? AppColors.orange : Colors.transparent,
        border: filled
            ? null
            : Border.all(color: AppColors.orange.withValues(alpha: 0.5)),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: filled ? AppColors.film : AppColors.orange,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: filled ? AppColors.film : AppColors.orange,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: filled ? AppColors.film : AppColors.orange,
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

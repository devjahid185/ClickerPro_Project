// lib/features/auth/presentation/reset_password_screen.dart
//
// Graphy7 — Reset Password (Dark Luxury Lens)
//
// Two password fields (new + confirm). On submit calls
// authRepository.resetPassword(token, newPassword). Success snackbar +
// pushAndRemoveUntil to LoginScreen. Error ? inline error.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _formError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

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

  Future<void> _handleSubmit() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            token: widget.token,
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password updated. Please sign in.',
            style: TextStyle(color: AppColors.film, fontSize: 13),
          ),
          backgroundColor: AppColors.voidElevated,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _formError = e.statusCode == 410
            ? 'This link has expired. Please try again.'
            : e.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      body: Stack(
        children: [
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
                        'Set a new\npassword',
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
                        'CHOOSE A STRONG PASSPHRASE',
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
                        margin: const EdgeInsets.symmetric(horizontal: 60),
                        height: 1,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 28),

                      _glassField(
                        controller: _passwordController,
                        label: 'New Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscured: _obscurePassword,
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 14),
                      _glassField(
                        controller: _confirmController,
                        label: 'Confirm Password',
                        icon: Icons.lock_reset_rounded,
                        isPassword: true,
                        obscured: _obscureConfirm,
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: _validateConfirm,
                      ),

                      if (_formError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _formError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      _gradientButton(
                        label: 'Update Password',
                        loading: _isLoading,
                        onTap: _isLoading ? null : _handleSubmit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
              Icons.lock_reset_rounded,
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
    bool isPassword = false,
    bool obscured = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.film.withValues(alpha: 0.08)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && obscured,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
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
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.filmDim,
                    size: 19,
                  ),
                  onPressed: onToggleObscure,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.orange,
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.4),
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
                      color: AppColors.film,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

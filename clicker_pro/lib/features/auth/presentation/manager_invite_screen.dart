// lib/features/auth/presentation/manager_invite_screen.dart
//
// Clicker Pro — Accept Invite (Manager onboarding) (Dark Luxury Lens)
//
// Code (6 mono cells like OTP) + name + email + password + confirm.
// Submit calls sessionController.acceptInvite(...). On 404/410 inline
// "Invalid or expired code". On success, root re-routes to Dashboard.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../screens/dashboard_screen.dart';
import '../../../theme/app_colors.dart';
import '../application/session_controller.dart';

class ManagerInviteScreen extends ConsumerStatefulWidget {
  const ManagerInviteScreen({super.key});

  @override
  ConsumerState<ManagerInviteScreen> createState() =>
      _ManagerInviteScreenState();
}

class _ManagerInviteScreenState extends ConsumerState<ManagerInviteScreen> {
  static const _codeLen = 6;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final List<TextEditingController> _codeControllers = List.generate(
    _codeLen,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeNodes = List.generate(
    _codeLen,
    (_) => FocusNode(),
  );

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _codeError;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final n in _codeNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  String? _validateName(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter name';
    if (t.length > 80) return 'Name is too long';
    return null;
  }

  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter email';
    if (!_emailRegex.hasMatch(t)) return 'Enter a valid email';
    return null;
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

  void _onCodeChanged(int i, String v) {
    if (_codeError != null) setState(() => _codeError = null);
    if (v.length > 1) {
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (var k = 0; k < _codeLen; k++) {
        _codeControllers[k].text = k < digits.length ? digits[k] : '';
      }
      final nextEmpty = _codeControllers.indexWhere((c) => c.text.isEmpty);
      if (nextEmpty == -1) {
        _codeNodes.last.unfocus();
      } else {
        _codeNodes[nextEmpty].requestFocus();
      }
      setState(() {});
      return;
    }
    if (v.isNotEmpty && i < _codeLen - 1) {
      _codeNodes[i + 1].requestFocus();
    }
    setState(() {});
  }

  KeyEventResult _onCodeKey(int i, FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_codeControllers[i].text.isEmpty && i > 0) {
        _codeNodes[i - 1].requestFocus();
        _codeControllers[i - 1].clear();
        setState(() {});
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _handleSubmit() async {
    setState(() => _codeError = null);
    if (_code.length < _codeLen) {
      setState(() => _codeError = 'Enter all 6 digits of the invite code.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .acceptInvite(
            code: _code,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      final state = ref.read(sessionControllerProvider);
      if (state.hasError) {
        _onError(state.error);
        return;
      }
      if (state.value != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _onError(e);
    } catch (_) {
      if (!mounted) return;
      _onError(null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onError(Object? err) {
    String message;
    if (err is ApiException &&
        (err.statusCode == 404 || err.statusCode == 410)) {
      message = 'Invalid or expired code';
    } else if (err is ApiException) {
      message = err.message;
    } else {
      message = 'Something went wrong.';
    }
    setState(() => _codeError = message);
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
                      const SizedBox(height: 32),
                      _smallBrandLogo(),
                      const SizedBox(height: 26),
                      Text(
                        'Accept your\ninvite',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: AppColors.film,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TEAM MANAGER · ACCESS GRANTED BY OWNER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10.5,
                          letterSpacing: 2.2,
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
                      const SizedBox(height: 22),

                      // ── Invite code cells ──────────────────────
                      Text(
                        '6-DIGIT INVITE CODE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          letterSpacing: 2,
                          color: AppColors.filmDim.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _codeLen; i++) ...[
                            _DigitCell(
                              controller: _codeControllers[i],
                              focusNode: _codeNodes[i],
                              hasError: _codeError != null,
                              onChanged: (v) => _onCodeChanged(i, v),
                              onKey: (n, e) => _onCodeKey(i, n, e),
                            ),
                            if (i != _codeLen - 1) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      if (_codeError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _codeError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      _glassField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: _validateName,
                      ),
                      const SizedBox(height: 14),
                      _glassField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),
                      _glassField(
                        controller: _passwordController,
                        label: 'Password',
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

                      const SizedBox(height: 22),

                      _gradientButton(
                        label: 'Accept Invite',
                        loading: _isLoading,
                        onTap: _isLoading ? null : _handleSubmit,
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Text(
                              'Back to Sign In',
                              style: TextStyle(
                                color: AppColors.gold.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
            child: const Icon(
              Icons.group_outlined,
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
    TextInputType? keyboardType,
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
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        style: TextStyle(color: AppColors.film, fontSize: 14.5),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.7),
            fontSize: 13.5,
          ),
          floatingLabelStyle: const TextStyle(
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
          errorStyle: const TextStyle(
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
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
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

// ─────────────────────────────────────────────────────────────────
// Internal digit cell (mirror of OtpScreen's cell, kept private here
// so manager invite is self-contained).
// ─────────────────────────────────────────────────────────────────
class _DigitCell extends StatefulWidget {
  const _DigitCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKey,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(FocusNode, KeyEvent) onKey;
  final bool hasError;

  @override
  State<_DigitCell> createState() => _DigitCellState();
}

class _DigitCellState extends State<_DigitCell> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_repaint);
    widget.controller.addListener(_repaint);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_repaint);
    widget.controller.removeListener(_repaint);
    super.dispose();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;
    final focused = widget.focusNode.hasFocus;

    Color borderColor;
    if (widget.hasError) {
      borderColor = Colors.redAccent.withValues(alpha: 0.7);
    } else if (focused) {
      borderColor = AppColors.orange.withValues(alpha: 0.85);
    } else if (filled) {
      borderColor = AppColors.gold.withValues(alpha: 0.7);
    } else {
      borderColor = Colors.white.withValues(alpha: 0.1);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 44,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.film.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Focus(
        onKeyEvent: widget.onKey,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          showCursor: true,
          cursorColor: AppColors.orange,
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: AppColors.film,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

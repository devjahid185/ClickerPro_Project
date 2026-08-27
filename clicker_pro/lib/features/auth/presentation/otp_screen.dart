// lib/features/auth/presentation/otp_screen.dart
//
// Graphy7 — OTP Verification (Dark Luxury Lens)
//
// 6 individual mono-numeric digit cells (48 × 56) with:
//   • auto-advance to the next cell on input
//   • auto-go-back on backspace at empty cell
//   • gold ring on filled, orange ring on focused
//
// Below: "Resend code in 0:30" countdown then a "Resend" button that calls
// authRepository.requestOtp again.
//
// On success:
//   • signup / login ? pushAndRemoveUntil to DashboardScreen (root flow)
//   • forgotPassword ? push ResetPasswordScreen with the returned token
// On 400/410 ? inline error + a single shake animation on the cell row.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../screens/dashboard_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/session_controller.dart';
import '../domain/otp_purpose.dart';
import 'login_screen.dart' show LoginScreen, slideFromRightRoute;
import 'reset_password_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.identifier, required this.purpose});

  final String identifier;
  final OtpPurpose purpose;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  static const _length = 6;

  final List<TextEditingController> _controllers = List.generate(
    _length,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(_length, (_) => FocusNode());

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shake;

  Timer? _resendTimer;
  int _resendSecondsLeft = 30;
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;

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

    _startResendTimer();

    // Focus the first cell once the screen is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _shakeCtrl.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSecondsLeft <= 1) {
        t.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft--);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int i, String value) {
    if (_error != null) setState(() => _error = null);
    if (value.length > 1) {
      // Likely a paste — distribute across cells.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var k = 0; k < _length; k++) {
        _controllers[k].text = k < digits.length ? digits[k] : '';
      }
      final nextEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
      if (nextEmpty == -1) {
        _nodes.last.unfocus();
        _handleVerify();
      } else {
        _nodes[nextEmpty].requestFocus();
      }
      setState(() {});
      return;
    }
    if (value.isNotEmpty && i < _length - 1) {
      _nodes[i + 1].requestFocus();
    }
    if (value.isNotEmpty && i == _length - 1) {
      _nodes[i].unfocus();
      if (_controllers.every((c) => c.text.isNotEmpty)) {
        _handleVerify();
      }
    }
    setState(() {});
  }

  KeyEventResult _onKey(int i, FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[i].text.isEmpty && i > 0) {
        _nodes[i - 1].requestFocus();
        _controllers[i - 1].clear();
        setState(() {});
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _handleResend() async {
    if (_resendSecondsLeft > 0 || _isResending) return;
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .requestOtp(identifier: widget.identifier, purpose: widget.purpose);
      if (!mounted) return;
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New code sent.',
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
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      _shakeCtrl.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not send the code.');
      _shakeCtrl.forward(from: 0);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleVerify() async {
    if (_code.length < _length) {
      setState(() => _error = 'Please enter all 6 digits.');
      _shakeCtrl.forward(from: 0);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      switch (widget.purpose) {
        case OtpPurpose.signup:
        case OtpPurpose.login:
          await ref
              .read(sessionControllerProvider.notifier)
              .verifyOtp(
                identifier: widget.identifier,
                code: _code,
                purpose: widget.purpose,
              );
          if (!mounted) return;
          final state = ref.read(sessionControllerProvider);
          if (state.hasError) {
            _onApiError(state.error);
            return;
          }
          if (state.value != null) {
            // The route MUST be named: the web nav shell tracks the current
            // route name to decide whether to draw the sidebar chrome. An
            // unnamed push left it stuck on '/otp' (a fullscreen route), so a
            // fresh registration landed on a broken, chrome-less dashboard
            // until a manual refresh (Heaven 2026-07-15).
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                settings: const RouteSettings(name: RouteNames.dashboard),
                builder: (_) => const DashboardScreen(),
              ),
              (route) => false,
            );
          }
          break;

        case OtpPurpose.forgotPassword:
          // Backend returns a Session for the verify endpoint — we use the
          // token as the reset-token semantic for the next screen.
          final session = await ref
              .read(authRepositoryProvider)
              .verifyOtp(
                identifier: widget.identifier,
                code: _code,
                purpose: widget.purpose,
              );
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            slideFromRightRoute(ResetPasswordScreen(token: session.token)),
          );
          break;
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _onApiError(e);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong.');
      _shakeCtrl.forward(from: 0);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Back navigation. Registration reaches this screen via
  /// pushAndRemoveUntil (the whole stack is cleared), so there is nothing to
  /// pop back to and a plain maybePop() would do nothing. Fall back to the
  /// Login screen in that case so the button always responds.
  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushAndRemoveUntil(
        slideFromRightRoute(const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onApiError(Object? err) {
    String message;
    if (err is ApiException &&
        (err.statusCode == 400 || err.statusCode == 410)) {
      message = 'Code is invalid or expired. Try again or resend.';
    } else if (err is ApiException) {
      message = err.message;
    } else {
      message = 'Something went wrong.';
    }
    setState(() => _error = message);
    _shakeCtrl.forward(from: 0);
  }

  String get _maskedIdentifier {
    final id = widget.identifier;
    if (id.contains('@')) {
      final parts = id.split('@');
      final user = parts[0];
      final visible = user.length <= 2
          ? user
          : '${user.substring(0, 2)}${'*' * (user.length - 2)}';
      return '$visible@${parts[1]}';
    }
    if (id.length <= 4) return id;
    return '${'*' * (id.length - 4)}${id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The stack is usually cleared before this screen, so the framework
      // can't pop it. Intercept the system back and route to Login ourselves.
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 36),
                    _smallBrandLogo(),
                    const SizedBox(height: 28),
                    Text(
                      'Verify your\ncode',
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
                      'ONE-TIME PASSCODE',
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
                    const SizedBox(height: 14),
                    Text(
                      'We sent a 6-digit code to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.filmDim.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskedIdentifier,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppText.bodyFontFamily,
                        fontSize: 13.5,
                        color: AppColors.gold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // -- Digit cells (with shake) ----------------
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(_shake.value, 0),
                        child: child,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _length; i++) ...[
                            _DigitCell(
                              controller: _controllers[i],
                              focusNode: _nodes[i],
                              onChanged: (v) => _onChanged(i, v),
                              onKey: (n, e) => _onKey(i, n, e),
                              hasError: _error != null,
                            ),
                            if (i != _length - 1) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    _gradientButton(
                      label: 'Verify',
                      loading: _isLoading,
                      onTap: _isLoading ? null : _handleVerify,
                    ),

                    const SizedBox(height: 18),

                    // -- Resend ---------------------------------
                    Center(
                      child: _resendSecondsLeft > 0
                          ? Text(
                              'Resend code in 0:${_resendSecondsLeft.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontFamily: AppText.bodyFontFamily,
                                fontSize: 12,
                                letterSpacing: 1.0,
                                color: AppColors.filmDim.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _isResending ? null : _handleResend,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: _isResending
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: AppColors.gold,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Resend code',
                                        style: TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
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
                onPressed: _handleBack,
              ),
            ),
          ),
        ],
        ),
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
              Icons.shield_outlined,
              size: 22,
              color: AppColors.orange,
            ),
          ),
        ],
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

/// Single digit cell — 48 × 56, mono numeric, gold ring on filled,
/// orange ring on focused.
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
      width: 48,
      height: 56,
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
          maxLength: null,
          showCursor: true,
          cursorColor: AppColors.orange,
          style: TextStyle(
            fontFamily: AppText.bodyFontFamily,
            color: AppColors.film,
            fontSize: 22,
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

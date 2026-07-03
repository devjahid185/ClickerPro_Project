// lib/shared/widgets/auth_glass_field.dart
//
// AuthGlassField — the shared, modern frosted-glass text field used on the
// Login and Register screens.
//
// Why a shared widget: Login and Register both floated their own near-identical
// `_glassField` helpers. They drifted (different radius, font size, colours),
// and both sat on dark video/photo backdrops as flat opaque "paper" boxes that
// looked cheap over the imagery. This one widget gives both screens a single,
// premium treatment:
//
//   • True glassmorphism — BackdropFilter blur behind a translucent dark fill,
//     so the field reads as frosted glass over any video frame / photo colour.
//   • Rounder, softer geometry — 18px radius, generous padding, 56px tall.
//   • Depth — a hairline white top-border and a soft drop shadow.
//   • Focus feedback — the border and glow bloom brand-orange while editing,
//     driven by a FocusNode (no rebuild of the whole form).
//
// White text + white-ish labels are intentional: these fields live on dark
// scrims where dark ink would be invisible (see the auth-screen backdrops).

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

class AuthGlassField extends StatefulWidget {
  const AuthGlassField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.obscured = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  /// When true, shows the eye toggle and honours [obscured].
  final bool isPassword;

  /// Current obscure state — owned by the parent so it can share one toggle
  /// across confirm/password pairs.
  final bool obscured;
  final VoidCallback? onToggleObscure;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AuthGlassField> createState() => _AuthGlassFieldState();
}

class _AuthGlassFieldState extends State<AuthGlassField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  static const double _radius = 18;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = AppColors.orange;
    final BorderRadius radius = BorderRadius.circular(_radius);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: _focused
                ? accent.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.30),
            blurRadius: _focused ? 22 : 16,
            spreadRadius: _focused ? -2 : -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              // Translucent dark glass — a hint of orange tint when focused.
              color: _focused
                  ? accent.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: radius,
              border: Border.all(
                color: _focused
                    ? accent.withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.18),
                width: _focused ? 1.6 : 1.1,
              ),
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.isPassword && widget.obscured,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              validator: widget.validator,
              onChanged: widget.onChanged,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              cursorColor: accent,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                floatingLabelStyle: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    widget.icon,
                    color: _focused
                        ? accent
                        : Colors.white.withValues(alpha: 0.75),
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        splashRadius: 20,
                        icon: Icon(
                          widget.obscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        onPressed: widget.onToggleObscure,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                // The container draws the border/fill; keep the field chrome-free.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                errorStyle: const TextStyle(
                  color: Color(0xFFFF8A80),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 0.9,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

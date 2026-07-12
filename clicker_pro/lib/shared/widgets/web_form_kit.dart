// lib/shared/widgets/web_form_kit.dart
//
// Clicker Pro — WEB-ONLY form building blocks (Sunset Studio).
//
// Shared by the web-native New Booking form, Event Details, Client
// Self-Booking and the Auth overlay so they all speak the exact same
// design language as the handoff (design_handoff_clickerpro_web):
//   • white section cards, radius 20, hairline #EBDDCE border
//   • inputs on cream #FBF6F0 with 12px radius and mono micro-labels
//   • orange pill buttons with hover darken + glow
//   • 44×24 animated toggles (orange ON / tan OFF)
//   • single-select chips (orange fill when active)
//
// Mobile never imports this file.

import 'package:flutter/material.dart';

import '../../theme/web_theme.dart';

/// White section card with an optional mono micro-label header row.
class WebFormCard extends StatelessWidget {
  const WebFormCard({
    super.key,
    required this.child,
    this.label,
    this.trailing,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final String? label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    final trailing = this.trailing;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null || trailing != null) ...[
            Row(
              children: [
                if (label != null)
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: WebTheme.label(size: 10, color: WebTheme.inkMuted),
                    ),
                  ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

/// Space Mono micro-label above an input.
class WebFieldLabel extends StatelessWidget {
  const WebFieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text.rich(
        TextSpan(
          text: text.toUpperCase(),
          style: WebTheme.label(size: 9, color: WebTheme.inkMuted),
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: WebTheme.label(size: 9, color: WebTheme.danger),
              ),
          ],
        ),
      ),
    );
  }
}

/// Handoff input: cream fill, sand border, radius 12, 12×16 padding.
class WebTextInput extends StatelessWidget {
  const WebTextInput({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.required = false,
    this.suffix,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final Widget? suffix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WebFieldLabel(label, required: required),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          style: WebTheme.bodyStyle(size: 13.5, weight: FontWeight.w500),
          cursorColor: WebTheme.orange,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WebTheme.bodyStyle(size: 13, color: WebTheme.inkFaint),
            filled: true,
            fillColor: WebTheme.pageBg,
            isDense: true,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WebTheme.rButton),
              borderSide: const BorderSide(color: WebTheme.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WebTheme.rButton),
              borderSide: const BorderSide(color: WebTheme.orange, width: 1.4),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WebTheme.rButton),
              borderSide: const BorderSide(color: WebTheme.hairline),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Text(
            errorText!,
            style: WebTheme.bodyStyle(
              size: 11.5,
              color: WebTheme.danger,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Tappable field styled like an input (date pickers etc.) with a leading
/// orange glyph.
class WebPickerField extends StatelessWidget {
  const WebPickerField({
    super.key,
    required this.label,
    required this.onTap,
    this.valueText,
    this.placeholder,
    this.icon = Icons.calendar_month_rounded,
    this.errorText,
    this.required = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? valueText;
  final String? placeholder;
  final IconData icon;
  final String? errorText;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final hasValue = valueText != null && valueText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WebFieldLabel(label, required: required),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: WebTheme.pageBg,
                borderRadius: BorderRadius.circular(WebTheme.rButton),
                border: Border.all(color: WebTheme.hairline),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: WebTheme.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasValue ? valueText! : (placeholder ?? 'Select'),
                      style: WebTheme.bodyStyle(
                        size: 13.5,
                        weight: FontWeight.w500,
                        color: hasValue ? WebTheme.ink : WebTheme.inkFaint,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded,
                      size: 18, color: WebTheme.inkMuted),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Text(
            errorText!,
            style: WebTheme.bodyStyle(
              size: 11.5,
              color: WebTheme.danger,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Solid orange pill button with hover darken + glow.
class WebPillButton extends StatefulWidget {
  const WebPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = WebTheme.orange,
    this.hoverColor = WebTheme.orangeDark,
    this.foreground = WebTheme.chromeInk,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;
  final Color hoverColor;
  final Color foreground;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  State<WebPillButton> createState() => _WebPillButtonState();
}

class _WebPillButtonState extends State<WebPillButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: WebTheme.fast,
          curve: WebTheme.ease,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hover ? widget.hoverColor : widget.color,
            borderRadius: BorderRadius.circular(WebTheme.rFull),
            boxShadow: _hover ? WebTheme.buttonGlow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 15, color: widget.foreground),
                const SizedBox(width: 7),
              ],
              Text(
                widget.label,
                style: WebTheme.bodyStyle(
                  size: widget.fontSize,
                  color: widget.foreground,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outline / tinted pill button (hover fills with the accent).
class WebTintButton extends StatefulWidget {
  const WebTintButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.accent = WebTheme.orange,
    this.tint = WebTheme.orangeTint,
    this.tintBorder = WebTheme.orangeTintBorder,
    this.textColor,
    this.fontSize = 12,
    this.mono = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color accent;
  final Color tint;
  final Color tintBorder;
  final Color? textColor;
  final double fontSize;
  final bool mono;
  final EdgeInsetsGeometry padding;

  @override
  State<WebTintButton> createState() => _WebTintButtonState();
}

class _WebTintButtonState extends State<WebTintButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fg = _hover
        ? WebTheme.chromeInk
        : (widget.textColor ?? widget.accent);
    final style = widget.mono
        ? WebTheme.label(size: widget.fontSize, color: fg, weight: FontWeight.w700)
        : WebTheme.bodyStyle(
            size: widget.fontSize, color: fg, weight: FontWeight.w700);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: WebTheme.fast,
          curve: WebTheme.ease,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hover ? widget.accent : widget.tint,
            borderRadius: BorderRadius.circular(WebTheme.rFull),
            border: Border.all(
              color: _hover ? widget.accent : widget.tintBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(widget.label, style: style),
            ],
          ),
        ),
      ),
    );
  }
}

/// The handoff's 44×24 toggle: orange track ON, tan track OFF.
class WebToggle extends StatelessWidget {
  const WebToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = WebTheme.orange,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: WebTheme.base,
          curve: WebTheme.ease,
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? activeColor : WebTheme.tan,
            borderRadius: BorderRadius.circular(WebTheme.rFull),
          ),
          child: AnimatedAlign(
            duration: WebTheme.base,
            curve: WebTheme.ease,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cream toggle row (label + sub + trailing [WebToggle]) used for Outdoor /
/// Distribution style rows.
class WebToggleRow extends StatelessWidget {
  const WebToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.activeColor = WebTheme.orange,
    this.background = WebTheme.pageBg,
    this.border = WebTheme.hairline,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(WebTheme.rRow),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WebTheme.bodyStyle(
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: WebTheme.bodyStyle(
                      size: 11.5,
                      color: WebTheme.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          WebToggle(value: value, onChanged: onChanged, activeColor: activeColor),
        ],
      ),
    );
  }
}

/// Single-select chip — orange (or custom accent) fill when selected.
class WebSelectChip extends StatefulWidget {
  const WebSelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = WebTheme.orange,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final IconData? icon;

  @override
  State<WebSelectChip> createState() => _WebSelectChipState();
}

class _WebSelectChipState extends State<WebSelectChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.selected
        ? WebTheme.chromeInk
        : (_hover ? WebTheme.ink : WebTheme.inkSoft);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: WebTheme.fast,
          curve: WebTheme.ease,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.accent
                : (_hover ? WebTheme.pageBgDeep : WebTheme.pageBg),
            borderRadius: BorderRadius.circular(WebTheme.rFull),
            border: Border.all(
              color: widget.selected ? widget.accent : WebTheme.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 13, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: WebTheme.bodyStyle(
                  size: 12.5,
                  color: fg,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sunset Studio auth backdrop — dark #2B1D12 canvas with two blurred glow
/// blobs (orange top-right, gold bottom-left), per the handoff Auth overlay.
class WebAuthBackdrop extends StatelessWidget {
  const WebAuthBackdrop({super.key});

  Widget _blob(Color color, double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WebTheme.chrome,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -140,
            right: -90,
            child: _blob(WebTheme.orange, 520, 0.34),
          ),
          Positioned(
            bottom: -160,
            left: -110,
            child: _blob(WebTheme.amber, 460, 0.22),
          ),
        ],
      ),
    );
  }
}

/// Frosted 440px auth card used over [WebAuthBackdrop] (radius 26, deep
/// shadow). On mobile it is a pass-through so phone auth is unchanged.
class WebAuthCard extends StatelessWidget {
  const WebAuthCard({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
      decoration: BoxDecoration(
        color: const Color(0x12FFF6EE),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x1FFFF6EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 60,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Mono "← BACK" style link.
class WebBackLink extends StatefulWidget {
  const WebBackLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<WebBackLink> createState() => _WebBackLinkState();
}

class _WebBackLinkState extends State<WebBackLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label.toUpperCase(),
          style: WebTheme.label(
            size: 10,
            color: _hover ? WebTheme.orangeDeep : WebTheme.inkMuted,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

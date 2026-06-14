// lib/features/bookings/presentation/widgets/lens_form_fields.dart
//
// Shared themed form primitives for the booking edit screen. Keeps the
// Dark Luxury Lens contract (subtle glass surface, soft hairline border,
// orange focus accent) localized so the screen stays declarative.
//
// All four primitives are deliberately stateless / dumb — they accept a
// value and an `onChanged` and let the controller own the state. This
// keeps them trivially testable and avoids a per-field StatefulWidget
// for a controller that already lives in Riverpod.

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Themed text input with optional error text + suffix slot.
///
/// `controller` is owned by the calling screen (so the screen can seed
/// initial values from the draft). The widget purposely avoids a
/// `setState` / `TextEditingController` lifecycle — that lives at the
/// screen level alongside the rest of the form.
class LensTextField extends StatelessWidget {
  const LensTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.onChanged,
    this.suffix,
    this.prefixIcon,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController controller;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              letterSpacing: 1.4,
              color: AppColors.film,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: TextStyle(color: AppColors.film, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.filmMuted.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(
                      prefixIcon,
                      size: 18,
                      color: AppColors.filmDim.withValues(alpha: 0.7),
                    ),
              suffixIcon: suffix,
              errorText: errorText,
              isDense: true,
              filled: true,
              fillColor: AppColors.line(0.04),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(focused: true),
              errorBorder: _border(error: true),
              focusedErrorBorder: _border(error: true, focused: true),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, bool error = false}) {
    final color = error
        ? AppColors.red
        : focused
        ? AppColors.orange
        : AppColors.line(0.08);
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: focused ? 1.2 : 1),
    );
  }
}

/// Single-pick dropdown styled to match [LensTextField].
class LensSelector<T> extends StatelessWidget {
  const LensSelector({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.itemLabel,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? errorText;
  final String Function(T)? itemLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              letterSpacing: 1.4,
              color: AppColors.film,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.line(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: errorText != null
                    ? AppColors.red
                    : AppColors.line(0.08),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.voidElevated,
                iconEnabledColor: AppColors.filmDim,
                style: TextStyle(color: AppColors.film, fontSize: 13.5),
                onChanged: onChanged,
                items: items
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel?.call(item) ?? item.toString()),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(color: AppColors.red, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

/// Toggle row with a label + optional sublabel.
class LensSwitchTile extends StatelessWidget {
  const LensSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.activeColor,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.line(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: AppColors.filmDim.withValues(alpha: 0.85),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: activeColor ?? AppColors.orange,
              inactiveThumbColor: AppColors.filmMuted,
              inactiveTrackColor: AppColors.line(0.08),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only "tap to pick" row. Shared by date pickers, time pickers,
/// and the client / package picker affordances. Keeps the visual
/// contract identical across all the picker rows on the edit screen.
class LensPickerRow extends StatelessWidget {
  const LensPickerRow({
    super.key,
    required this.label,
    required this.valueText,
    required this.onTap,
    this.errorText,
    this.icon,
    this.placeholder,
  });

  final String label;
  final String? valueText;
  final String? placeholder;
  final IconData? icon;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = valueText != null && valueText!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              letterSpacing: 1.4,
              color: AppColors.film,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.line(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: errorText != null
                        ? AppColors.red
                        : AppColors.line(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: AppColors.filmDim.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        hasValue ? valueText! : (placeholder ?? 'Tap to pick'),
                        style: TextStyle(
                          color: hasValue
                              ? Colors.white
                              : AppColors.filmMuted.withValues(alpha: 0.7),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.filmMuted.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(color: AppColors.red, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

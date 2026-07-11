// lib/features/bookings/presentation/web_packages.dart
//
// Graphy7 — WEB-ONLY packages (Sunset Studio, from
// design_handoff_clickerpro_web — Screen 6, MOD-25).
//
// Per the handoff: an intro line ("Selecting a package in the booking form
// auto-fills the payment total.") + orange "+ Add Package" pill, then a 3-col
// grid of cards with a 4px colored top border (orange / gold / purple):
// name (Sora 800) + tag pill (POPULAR/VALUE/STARTER), net price in orange with
// the struck original beside it (when a discount exists), a 2-col spec grid of
// tiles (micro label + bold value), and Edit (orange-tint, hover fills orange)
// / Delete (red-tint, hover fills red) buttons. Hover lifts the card −4px.
//
// Data comes from the same `packagesProvider` the mobile screen uses — no new
// business logic, only a web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/currency.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/booking_providers.dart';
import '../domain/package.dart';

/// The wide-web packages grid. Pure presentation over the existing providers.
class WebPackages extends ConsumerWidget {
  const WebPackages({
    super.key,
    this.canManage = false,
    this.onEdit,
    this.onAdd,
    this.onDelete,
  });

  final bool canManage;

  /// Opens the edit sheet for a package, wired by the host screen.
  final void Function(Package package)? onEdit;

  /// Opens the create sheet, wired by the host screen.
  final VoidCallback? onAdd;

  /// Deletes a package (with the host screen's confirm flow).
  final void Function(Package package)? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(packagesProvider);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          WebEntrance(
            delay: const Duration(milliseconds: 50),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selecting a package in the booking form auto-fills '
                    'the payment total.',
                    style: WebTheme.bodyStyle(
                        size: 12.5, color: WebTheme.inkMuted),
                  ),
                ),
                if (canManage && onAdd != null) ...[
                  const SizedBox(width: 16),
                  WebHoverHighlight(
                    onTap: onAdd,
                    borderRadius: WebTheme.rFull,
                    builder: (context, hovering) => AnimatedContainer(
                      duration: WebTheme.base,
                      curve: WebTheme.ease,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: hovering
                            ? WebTheme.orangeDark
                            : WebTheme.orange,
                        borderRadius:
                            BorderRadius.circular(WebTheme.rFull),
                        boxShadow: WebTheme.buttonGlow,
                      ),
                      child: Text('+ Add Package',
                          style: WebTheme.bodyStyle(
                              size: 13,
                              weight: FontWeight.w700,
                              color: WebTheme.chromeInk)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => const _Grid(children: [
              _CardSkeleton(),
              _CardSkeleton(),
              _CardSkeleton(),
            ]),
            error: (_, _) =>
                const _Message(text: 'Could not load packages.'),
            data: (list) {
              if (list.isEmpty) {
                return const _Message(text: 'No packages yet.');
              }
              // Premium tiers lead, matching the handoff's card order.
              final sorted = [...list]
                ..sort((a, b) => b.basePrice.compareTo(a.basePrice));
              return _Grid(
                children: [
                  for (var i = 0; i < sorted.length; i++)
                    WebEntrance(
                      delay:
                          Duration(milliseconds: (70 * i).clamp(0, 420)),
                      offset: 8,
                      child: _PackageCard(
                        package: sorted[i],
                        index: i,
                        canManage: canManage,
                        onEdit: onEdit == null
                            ? null
                            : () => onEdit!(sorted[i]),
                        onDelete: onDelete == null
                            ? null
                            : () => onDelete!(sorted[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Responsive 3-up / 2-up / 1-up grid of cards.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
        const gap = 16.0;
        final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: cardW, child: child),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────── CARD
class _PackageCard extends StatefulWidget {
  const _PackageCard({
    required this.package,
    required this.index,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final Package package;
  final int index;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _hover = false;

  static const _accents = [WebTheme.orange, WebTheme.amber, WebTheme.night];
  static const _tags = ['POPULAR', 'VALUE', 'STARTER'];

  @override
  Widget build(BuildContext context) {
    final p = widget.package;
    final accent = _accents[widget.index % _accents.length];
    final tag = widget.index < _tags.length ? _tags[widget.index] : null;
    final net = p.basePrice - p.discount;
    final hasDiscount = p.discount > 0;
    final specs = _specs(p);
    final noMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: noMotion ? Duration.zero : WebTheme.base,
        curve: WebTheme.ease,
        transform: Matrix4.translationValues(
            0, _hover && !noMotion ? -4 : 0, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          border: Border.all(
              color: _hover ? WebTheme.orangeTintBorder : WebTheme.hairline),
          boxShadow:
              _hover ? WebTheme.cardShadowHover : WebTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 4px colored top border.
            Container(height: 4, color: accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WebTheme.displayStyle(
                              size: 18, weight: FontWeight.w800),
                        ),
                      ),
                      if (tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(WebTheme.rFull),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.35)),
                          ),
                          child: Text(tag,
                              style: WebTheme.label(
                                  size: 8.5,
                                  color: accent == WebTheme.amber
                                      ? WebTheme.amberText
                                      : accent,
                                  tracking: 0.1)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _money(net),
                            style: WebTheme.displayStyle(
                                size: 26,
                                weight: FontWeight.w800,
                                color: WebTheme.orange),
                          ),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          _money(p.basePrice),
                          style: TextStyle(
                            fontFamily: WebTheme.mono,
                            fontSize: 12,
                            color: WebTheme.inkFaint,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: WebTheme.inkFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  // 2-col spec grid of tiles.
                  if (specs.isEmpty)
                    Text('No inclusions listed.',
                        style: WebTheme.bodyStyle(
                            size: 12, color: WebTheme.inkFaint))
                  else
                    LayoutBuilder(builder: (context, c) {
                      const gap = 8.0;
                      final w = (c.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final s in specs)
                            SizedBox(
                              width: w,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: WebTheme.pageBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: WebTheme.innerLine),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s.$1,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: WebTheme.label(
                                            size: 7.5,
                                            color: WebTheme.inkMuted,
                                            tracking: 0.1)),
                                    const SizedBox(height: 3),
                                    Text(s.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: WebTheme.bodyStyle(
                                            size: 12,
                                            weight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  if (widget.canManage &&
                      (widget.onEdit != null ||
                          widget.onDelete != null)) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (widget.onEdit != null)
                          Expanded(
                            child: _ActionButton(
                              label: 'Edit',
                              base: WebTheme.orangeTint,
                              baseBorder: WebTheme.orangeTintBorder,
                              baseText: WebTheme.orangeDeep,
                              fill: WebTheme.orange,
                              onTap: widget.onEdit!,
                            ),
                          ),
                        if (widget.onEdit != null &&
                            widget.onDelete != null)
                          const SizedBox(width: 8),
                        if (widget.onDelete != null)
                          Expanded(
                            child: _ActionButton(
                              label: 'Delete',
                              base: WebTheme.dangerTint,
                              baseBorder: WebTheme.dangerTintBorder,
                              baseText: WebTheme.danger,
                              fill: WebTheme.danger,
                              onTap: widget.onDelete!,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// (label, value) spec tiles from the package's structured fields plus its
  /// free-form inclusions.
  static List<(String, String)> _specs(Package p) {
    final out = <(String, String)>[];
    if (p.coverageHours != null) {
      out.add(('COVERAGE', '${_trim(p.coverageHours!)} hrs'));
    }
    if ((p.photographerCount ?? 0) > 0) {
      out.add(('PHOTOGRAPHERS', '${p.photographerCount}'));
    }
    if ((p.cinematographerCount ?? 0) > 0) {
      out.add(('CINEMATOGRAPHERS', '${p.cinematographerCount}'));
    }
    final extras = <String>[
      ...?p.inclusions,
      if ((p.inclusions ?? const []).isEmpty) ...?p.items,
    ];
    for (final s in extras) {
      if (s.trim().isEmpty) continue;
      out.add(('INCLUDED', s.trim()));
      if (out.length >= 8) break;
    }
    return out;
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// Tinted action button that fills solid on hover (Edit orange / Delete red).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.base,
    required this.baseBorder,
    required this.baseText,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final Color base;
  final Color baseBorder;
  final Color baseText;
  final Color fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: hovering ? fill : base,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          border: Border.all(color: hovering ? fill : baseBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: WebTheme.bodyStyle(
              size: 12.5,
              weight: FontWeight.w700,
              color: hovering ? Colors.white : baseText,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────── LOADING / EMPTY
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebShimmer(width: 120, height: 18, borderRadius: 6),
          SizedBox(height: 12),
          WebShimmer(width: 90, height: 26, borderRadius: 6),
          SizedBox(height: 20),
          WebShimmer(height: 40, borderRadius: 10),
          SizedBox(height: 8),
          WebShimmer(height: 40, borderRadius: 10),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Center(
        child: Text(
          text,
          style: WebTheme.bodyStyle(size: 13, color: WebTheme.inkMuted),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HELPERS
String _money(num v) {
  final taka = v.round();
  final s = taka.toString();
  final buf = StringBuffer();
  final reversed = s.split('').reversed.toList();
  for (var i = 0; i < reversed.length; i++) {
    if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
    buf.write(reversed[i]);
  }
  return ActiveCurrency.value.wrap(buf.toString().split('').reversed.join());
}

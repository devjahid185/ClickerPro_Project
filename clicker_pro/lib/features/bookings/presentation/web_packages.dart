// lib/features/bookings/presentation/web_packages.dart
//
// Graphy7 — WEB-ONLY packages (Graphy7 Design).
//
// A desktop package grid, rendered ONLY on wide web. The mobile packages body
// is 100% untouched (PackagesScreen routes here only when
// kIsWeb && width >= 900). Ported from the design source's "Packages" screen:
// a responsive 3-up grid of pricing cards — tag, name, price, an inclusions
// checklist, and a footer with an Edit action.
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
  const WebPackages({super.key, this.canManage = false, this.onEdit});

  final bool canManage;

  /// Opens the (mobile) edit sheet for a package, wired by the host screen.
  final void Function(Package package)? onEdit;

  static const double _maxContentWidth = 1200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(packagesProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WebTheme.sp6,
            WebTheme.sp5,
            WebTheme.sp6,
            WebTheme.sp7,
          ),
          children: [
            WebEntrance(child: _Header(count: async.value?.length)),
            const SizedBox(height: WebTheme.sp5),
            WebEntrance(
              delay: const Duration(milliseconds: 55),
              child: async.when(
                loading: () => const _Grid(children: [
                  _CardSkeleton(),
                  _CardSkeleton(),
                  _CardSkeleton(),
                ]),
                error: (_, _) => const _Message(
                  icon: Icons.inventory_2_outlined,
                  text: 'Could not load packages.',
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const _Message(
                      icon: Icons.inventory_2_outlined,
                      text: 'No packages yet.',
                    );
                  }
                  // Most-booked-looking first: sort by price descending so the
                  // premium tiers lead, matching the design's card order.
                  final sorted = [...list]
                    ..sort((a, b) => b.basePrice.compareTo(a.basePrice));
                  return _Grid(
                    children: [
                      for (final p in sorted)
                        _PackageCard(
                          package: p,
                          canManage: canManage,
                          onEdit: onEdit == null ? null : () => onEdit!(p),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HEADER
class _Header extends StatelessWidget {
  const _Header({this.count});
  final int? count;

  @override
  Widget build(BuildContext context) {
    final n = count == null ? '—' : '$count';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Packages',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: WebTheme.ink,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$n active packages · pricing & inclusions',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: WebTheme.inkMuted,
          ),
        ),
      ],
    );
  }
}

/// Responsive 3-up / 2-up / 1-up grid of equal-height cards.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
        const gap = WebTheme.sp4;
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

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.canManage,
    required this.onEdit,
  });

  final Package package;
  final bool canManage;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final features = _features(package);
    final price = package.basePrice - package.discount;

    return WebHoverLift(
      borderRadius: WebTheme.rPanel,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rPanel),
          border: Border.all(color: WebTheme.hairline),
          boxShadow: WebTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PACKAGE',
              style: TextStyle(
                fontFamily: WebTheme.mono,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
                color: WebTheme.inkFaint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              package.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: WebTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatBdt((price * 100).round()),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
                color: WebTheme.orange,
              ),
            ),
            const SizedBox(height: 15),
            const Divider(height: 1, color: WebTheme.hairline),
            const SizedBox(height: 15),
            if (features.isEmpty)
              const Text(
                'No inclusions listed.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.inkFaint,
                ),
              )
            else
              for (final f in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 17, color: WebTheme.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: WebTheme.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            if (canManage && onEdit != null) ...[
              const SizedBox(height: 6),
              const Divider(height: 1, color: WebTheme.hairline),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: WebHoverLift(
                  onTap: onEdit,
                  borderRadius: WebTheme.rChip,
                  enableShadow: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: WebTheme.surface,
                      borderRadius: BorderRadius.circular(WebTheme.rChip),
                      border: Border.all(color: WebTheme.hairlineStrong),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded,
                            size: 16, color: WebTheme.ink),
                        SizedBox(width: 5),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: WebTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Human-readable inclusion lines from the package's structured fields,
  /// falling back to its free-form inclusions/items list.
  static List<String> _features(Package p) {
    final out = <String>[];
    if (p.coverageHours != null) {
      out.add('${_trim(p.coverageHours!)} hours coverage');
    }
    if ((p.photographerCount ?? 0) > 0) {
      final n = p.photographerCount!;
      out.add('$n photographer${n > 1 ? 's' : ''}');
    }
    if ((p.cinematographerCount ?? 0) > 0) {
      final n = p.cinematographerCount!;
      out.add('$n cinematographer${n > 1 ? 's' : ''}');
    }
    for (final s in (p.inclusions ?? const <String>[])) {
      if (s.trim().isNotEmpty) out.add(s.trim());
    }
    if (out.isEmpty) {
      for (final s in (p.items ?? const <String>[])) {
        if (s.trim().isNotEmpty) out.add(s.trim());
      }
    }
    return out.take(6).toList();
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
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
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          WebShimmer(width: 60, height: 10, borderRadius: 4),
          SizedBox(height: 12),
          WebShimmer(width: 120, height: 18, borderRadius: 6),
          SizedBox(height: 12),
          WebShimmer(width: 90, height: 26, borderRadius: 6),
          SizedBox(height: 20),
          WebShimmer(height: 12, borderRadius: 4),
          SizedBox(height: 10),
          WebShimmer(height: 12, borderRadius: 4),
          SizedBox(height: 10),
          WebShimmer(height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebTheme.sageTint,
                borderRadius: BorderRadius.circular(WebTheme.rChip),
              ),
              child: Icon(icon, color: WebTheme.inkMuted, size: 24),
            ),
            const SizedBox(height: WebTheme.sp3),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WebTheme.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HELPERS
String _formatBdt(int minor) {
  final taka = (minor / 100).round();
  final s = taka.toString();
  final buf = StringBuffer();
  final reversed = s.split('').reversed.toList();
  for (var i = 0; i < reversed.length; i++) {
    if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
    buf.write(reversed[i]);
  }
  return ActiveCurrency.value.wrap(buf.toString().split('').reversed.join());
}

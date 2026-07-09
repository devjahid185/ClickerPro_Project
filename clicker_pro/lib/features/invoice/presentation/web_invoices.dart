// lib/features/invoice/presentation/web_invoices.dart
//
// Graphy7 — WEB-ONLY invoices (Graphy7 Design).
//
// A desktop invoice dashboard, rendered ONLY on wide web. The mobile invoice
// list body is 100% untouched (InvoiceScreen routes here only when
// kIsWeb && width >= 900 AND no single invoice is being shown). Ported from the
// design source's "Invoices" screen: a KPI row (revenue / outstanding / paid /
// count) over a white invoice table.
//
// Data comes from the same `invoiceListControllerProvider` the mobile list
// uses — no new business logic, only a web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/currency.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/invoice_providers.dart';
import '../domain/invoice.dart';

/// The wide-web invoices dashboard. Pure presentation over existing providers.
class WebInvoices extends ConsumerWidget {
  const WebInvoices({super.key, this.onTapInvoice});

  final void Function(Invoice invoice)? onTapInvoice;

  static const double _maxContentWidth = 1280;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(invoiceListControllerProvider);

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
            const WebEntrance(child: _Header()),
            const SizedBox(height: WebTheme.sp5),
            WebEntrance(
              delay: const Duration(milliseconds: 55),
              child: _KpiRow(invoices: async.value ?? const []),
            ),
            const SizedBox(height: WebTheme.sp4),
            WebEntrance(
              delay: const Duration(milliseconds: 110),
              child: async.when(
                loading: () => const _TableCard(child: _TableSkeleton()),
                error: (_, _) => const _TableCard(
                  child: _TableMessage(message: 'Could not load invoices.'),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const _TableCard(
                      child: _TableMessage(message: 'No invoices yet.'),
                    );
                  }
                  final rows = [...list]
                    ..sort((a, b) => (b.sentAt ?? DateTime(0))
                        .compareTo(a.sentAt ?? DateTime(0)));
                  return _TableCard(
                    child: _InvoiceTable(rows: rows, onTap: onTapInvoice),
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Invoices',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: WebTheme.ink,
            height: 1.0,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Billing & payment tracking',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: WebTheme.inkMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── KPI ROW
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.invoices});
  final List<Invoice> invoices;

  bool _isPaid(Invoice i) =>
      i.status.toUpperCase() == 'PAID' || i.due <= 0;

  @override
  Widget build(BuildContext context) {
    var revenue = 0.0, outstanding = 0.0, paid = 0.0;
    var unpaidCount = 0;
    for (final i in invoices) {
      revenue += i.total;
      if (_isPaid(i)) {
        paid += i.total;
      } else {
        outstanding += i.due;
        unpaidCount++;
      }
    }

    final cards = <Widget>[
      _KpiCard(
        label: 'TOTAL BILLED',
        value: _formatBdt((revenue * 100).round()),
        sub: '${invoices.length} invoices',
        icon: Icons.payments_rounded,
        accent: WebTheme.orange,
      ),
      _KpiCard(
        label: 'OUTSTANDING',
        value: _formatBdt((outstanding * 100).round()),
        sub: '$unpaidCount unpaid',
        icon: Icons.schedule_rounded,
        accent: WebTheme.warning,
      ),
      _KpiCard(
        label: 'COLLECTED',
        value: _formatBdt((paid * 100).round()),
        sub: '${invoices.length - unpaidCount} settled',
        icon: Icons.check_circle_rounded,
        accent: WebTheme.success,
      ),
      _KpiCard(
        label: 'INVOICES',
        value: '${invoices.length}',
        sub: 'this workspace',
        icon: Icons.receipt_long_rounded,
        accent: WebTheme.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 720;
        if (narrow) {
          return Wrap(
            spacing: WebTheme.sp4,
            runSpacing: WebTheme.sp4,
            children: [
              for (final card in cards)
                SizedBox(width: (c.maxWidth - WebTheme.sp4) / 2, child: card),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: WebTheme.sp4),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WebTheme.sp5),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: WebTheme.mono,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.inkFaint,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: WebTheme.ink,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: WebTheme.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── TABLE
class _TableCard extends StatelessWidget {
  const _TableCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _InvoiceTable extends StatelessWidget {
  const _InvoiceTable({required this.rows, required this.onTap});
  final List<Invoice> rows;
  final void Function(Invoice invoice)? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderRow(),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: WebTheme.hairline),
          _InvoiceRow(invoice: rows[i], onTap: onTap),
        ],
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: const BoxDecoration(
        color: WebTheme.pageBgDeep,
        border: Border(bottom: BorderSide(color: WebTheme.hairline)),
      ),
      child: Row(
        children: const [
          Expanded(flex: 3, child: _HLabel('PACKAGE')),
          Expanded(flex: 3, child: _HLabel('COMPANY')),
          Expanded(flex: 2, child: _HLabel('DATE')),
          Expanded(flex: 2, child: _HLabel('AMOUNT', align: TextAlign.right)),
          Expanded(flex: 2, child: _HLabel('STATUS', align: TextAlign.right)),
        ],
      ),
    );
  }
}

class _HLabel extends StatelessWidget {
  const _HLabel(this.text, {this.align = TextAlign.left});
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontFamily: WebTheme.mono,
        fontSize: 9.5,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w500,
        color: WebTheme.inkFaint,
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice, required this.onTap});
  final Invoice invoice;
  final void Function(Invoice invoice)? onTap;

  Color get _statusColor {
    final paid = invoice.status.toUpperCase() == 'PAID' || invoice.due <= 0;
    if (paid) return WebTheme.success;
    if (invoice.advance > 0) return WebTheme.warning;
    return WebTheme.danger;
  }

  String get _statusLabel {
    if (invoice.status.toUpperCase() == 'PAID' || invoice.due <= 0) {
      return 'Paid';
    }
    if (invoice.advance > 0) return 'Partial';
    return 'Unpaid';
  }

  @override
  Widget build(BuildContext context) {
    final pkg = invoice.packageName.trim().isNotEmpty
        ? invoice.packageName.trim()
        : 'Invoice';
    final company = invoice.companyName.trim().isNotEmpty
        ? invoice.companyName.trim()
        : '—';
    final date =
        invoice.sentAt == null ? '—' : DateFormat('d MMM yyyy').format(invoice.sentAt!);

    return WebHoverHighlight(
      borderRadius: 0,
      onTap: onTap == null ? null : () => onTap!(invoice),
      builder: (context, hovering) {
        return AnimatedContainer(
          duration: WebTheme.fast,
          curve: WebTheme.ease,
          color: hovering ? WebTheme.sageTintSoft : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  pkg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: WebTheme.ink,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.inkSoft,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.inkMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatBdt((invoice.total * 100).round()),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: WebTheme.ink,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(WebTheme.rFull),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────── LOADING / EMPTY
class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: List.generate(
          5,
          (i) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Expanded(flex: 3, child: WebShimmer(height: 14, borderRadius: 6)),
                SizedBox(width: 16),
                Expanded(flex: 3, child: WebShimmer(height: 14, borderRadius: 6)),
                SizedBox(width: 16),
                Expanded(flex: 2, child: WebShimmer(height: 14, borderRadius: 6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableMessage extends StatelessWidget {
  const _TableMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
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
              child: const Icon(Icons.receipt_long_outlined,
                  color: WebTheme.inkMuted, size: 24),
            ),
            const SizedBox(height: WebTheme.sp3),
            Text(
              message,
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

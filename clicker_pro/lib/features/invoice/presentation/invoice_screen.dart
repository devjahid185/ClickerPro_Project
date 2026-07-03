// lib/features/invoice/presentation/invoice_screen.dart
//
// Invoice view for a single booking. Layout:
//
//   ┌─────────────────────────────┐
//   │ AppBar: ← Invoice           │
//   ├─────────────────────────────┤
//   │ Company logo + name header  │
//   ├─────────────────────────────┤
//   │ Event details card          │
//   │ Team section card           │
//   │ Payment summary card        │
//   ├─────────────────────────────┤
//   │ Share buttons row           │
//   │ PDF export button           │
//   └─────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/pdf/pdf_export.dart';
import '../../../core/format/booking_format.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../bookings/application/booking_providers.dart';
import '../application/invoice_providers.dart';
import '../domain/invoice.dart';
import '../../../theme/app_theme.dart';

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key, this.invoice});

  /// When provided, the screen shows that one invoice's detail. When null
  /// (e.g. opened from the dashboard "Invoice" quick action), it shows the
  /// list of all invoices so the user can pick one — instead of a dead
  /// "No invoice data" screen.
  final Invoice? invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = invoice;

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          // Detail is a "sheet" per the design (close), the list is a page.
          icon: Icon(
            inv == null ? Icons.arrow_back : Icons.close_rounded,
            color: AppColors.film,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(
          inv == null ? 'Invoices' : 'Invoice',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * 18,
          ),
        ),
      ),
      body: inv == null
          ? _InvoiceList()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InvoicePaper(invoice: inv),
                  const SizedBox(height: 14),
                  _buildActionGrid(context, ref, inv),
                ],
              ),
            ),
    );
  }

  // ─── Action grid (.dc.html): Copy · WhatsApp · PDF ─────────────────
  // Copy is a plain white tile, WhatsApp a green-tinted one, PDF the solid
  // orange primary. (The old Messenger button is gone per the design; the
  // system share sheet is still reachable from the exported PDF.)
  Widget _buildActionGrid(BuildContext context, WidgetRef ref, Invoice inv) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.copy_rounded,
            label: 'Copy',
            style: _ActionStyle.plain,
            onTap: () {
              Clipboard.setData(ClipboardData(text: _invoiceText(inv)));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invoice copied to clipboard')),
              );
            },
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ActionTile(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            style: _ActionStyle.whatsapp,
            onTap: () => _shareViaWhatsApp(context, ref, inv),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ActionTile(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            style: _ActionStyle.primary,
            onTap: () => _exportPdf(context, inv),
          ),
        ),
      ],
    );
  }

  /// The [Invoice] model itself carries no client name/phone or event date/
  /// time/venue — only `eventId`, the package, and the money totals. Those
  /// fields live on the linked [Booking], so look it up (matched by the
  /// invoice's `eventId` against the booking's server `remoteId`) before
  /// opening the WhatsApp composer. Previously this always sent empty
  /// strings, which rendered the message template's {name}/{date}/{venue}
  /// placeholders blank — a WhatsApp message with nothing meaningful in it.
  Future<void> _shareViaWhatsApp(
    BuildContext context,
    WidgetRef ref,
    Invoice inv,
  ) async {
    final navigator = Navigator.of(context);
    final booking = await ref
        .read(bookingRepositoryProvider)
        .getByRemoteId(inv.eventId);

    navigator.pushNamed(
      RouteNames.whatsappShare,
      arguments: <String, String>{
        'clientName': booking?.clientName ?? '',
        'clientPhone': booking?.clientPhone ?? '',
        'eventName': inv.packageName.isNotEmpty
            ? inv.packageName
            : (booking?.title ?? ''),
        'eventDate': booking == null
            ? ''
            : BookingFormat.dateTime(booking.date, lang: 'en'),
        'eventTime': booking == null
            ? ''
            : BookingFormat.clockRange(
                booking.startTime,
                booking.endTime,
                lang: 'en',
              ),
        'venue': booking?.venue ?? '',
        'total': '৳${inv.total.toStringAsFixed(0)}',
        'advance': '৳${inv.advance.toStringAsFixed(0)}',
        'due': '৳${inv.due.toStringAsFixed(0)}',
        'packageName': inv.packageName,
      },
    );
  }

  Future<void> _exportPdf(BuildContext context, Invoice inv) async {
    final messenger = ScaffoldMessenger.of(context);
    final team = <List<String>>[
      for (var i = 0; i < inv.teamNames.length; i++)
        [
          inv.teamNames[i],
          i < inv.teamPhones.length ? inv.teamPhones[i] : '—',
        ],
    ];
    try {
      await PdfExporter.share(
        PdfDocumentData(
          documentTitle: 'Invoice',
          fileName: 'invoice_${inv.id}',
          companyName: inv.companyName,
          companyPhone: inv.companyPhone,
          subtitle: inv.packageName.isEmpty
              ? 'Status: ${inv.status}'
              : '${inv.packageName} · ${inv.status}',
          summary: [
            PdfRow('Package', inv.packageName.isEmpty ? '—' : inv.packageName),
            PdfRow('Total', '৳ ${inv.total.toStringAsFixed(0)}'),
            PdfRow('Advance', '৳ ${inv.advance.toStringAsFixed(0)}'),
            PdfRow('Due', '৳ ${inv.due.toStringAsFixed(0)}', emphasize: true),
          ],
          table: team.isEmpty
              ? null
              : PdfTable(headers: const ['Team', 'Phone'], rows: team),
          footnote: 'Generated by Clicker Pro',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not create PDF: $e')),
      );
    }
  }

  String _invoiceText(Invoice inv) {
    final buf = StringBuffer()
      ..writeln('INVOICE')
      ..writeln('Package: ${inv.packageName}')
      ..writeln('Status: ${inv.status}')
      ..writeln('Total: ৳${inv.total.toStringAsFixed(0)}')
      ..writeln('Advance: ৳${inv.advance.toStringAsFixed(0)}')
      ..writeln('Due: ৳${inv.due.toStringAsFixed(0)}');
    if (inv.teamNames.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('Team:');
      for (var i = 0; i < inv.teamNames.length; i++) {
        final phone = i < inv.teamPhones.length
            ? ' (${inv.teamPhones[i]})'
            : '';
        buf.writeln('  ${inv.teamNames[i]}$phone');
      }
    }
    return buf.toString();
  }
}

// ─── Shared private widgets ──────────────────────────────────────────

/// The .dc.html "invoice paper": one white card that reads like a printed
/// invoice — studio header over a 2px orange rule, mono INVOICE number,
/// team list, then the package / advance / due money block.
class _InvoicePaper extends StatelessWidget {
  const _InvoicePaper({required this.invoice});

  final Invoice invoice;

  String _money(double v) =>
      BookingFormat.money(v, lang: 'en', bnNumerals: false);

  /// "#INV-XXXX" — last 4 characters of the id, matching the mock's
  /// "#INV-0042" without inventing a sequence the backend doesn't have.
  String get _number {
    final id = invoice.id.replaceAll('-', '');
    final tail = id.length > 4 ? id.substring(id.length - 4) : id;
    return '#INV-${tail.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (invoice.status.toLowerCase()) {
      'paid' => AppColors.green,
      'sent' => AppColors.gold,
      _ => AppColors.filmDim,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            spreadRadius: -16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Studio ↔ INVOICE header over the signature 2px orange rule.
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.orange, width: 2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.companyName.isNotEmpty
                            ? invoice.companyName
                            : 'ClickerPro',
                        style: TextStyle(
                          color: AppColors.film,
                          fontFamily: AppText.brandFontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.02 * 17,
                        ),
                      ),
                      if (invoice.companyPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          invoice.companyPhone,
                          style: TextStyle(
                            color: AppColors.filmMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'INVOICE',
                      style: TextStyle(
                        fontFamily: AppText.monoFontFamily,
                        fontSize: 10,
                        letterSpacing: 1.0,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _number,
                      style: TextStyle(
                        color: AppColors.film,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        invoice.status.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppText.monoFontFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Team list.
          if (invoice.teamNames.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'TEAM',
              style: TextStyle(
                fontFamily: AppText.monoFontFamily,
                fontSize: 9,
                letterSpacing: 1.0,
                color: AppColors.filmMuted,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < invoice.teamNames.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.teamNames[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.filmDim,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    if (i < invoice.teamPhones.length)
                      Text(
                        invoice.teamPhones[i],
                        style: TextStyle(
                          color: AppColors.filmMuted,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
          ],

          // Money block: package · advance · due.
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line(0.07))),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.packageName.isNotEmpty
                              ? invoice.packageName
                              : 'Package',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.film,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        _money(invoice.total),
                        style: TextStyle(
                          color: AppColors.film,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Advance paid',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '− ${_money(invoice.advance)}',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.orange, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Due',
                        style: TextStyle(
                          color: AppColors.film,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _money(invoice.due),
                        style: TextStyle(
                          color: invoice.due > 0
                              ? AppColors.red
                              : AppColors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.02 * 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual style of an invoice action tile.
enum _ActionStyle { plain, whatsapp, primary }

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.style,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final _ActionStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color? borderColor, Color fg, List<BoxShadow>? shadow) =
        switch (style) {
      _ActionStyle.plain => (
        AppColors.surface,
        AppColors.line(0.08),
        AppColors.filmDim,
        null,
      ),
      _ActionStyle.whatsapp => (
        AppColors.greenSoft,
        AppColors.green.withValues(alpha: 0.2),
        AppColors.green,
        null,
      ),
      _ActionStyle.primary => (
        AppColors.orange,
        null,
        Colors.white,
        [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.55),
            blurRadius: 20,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(13),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor),
            boxShadow: shadow,
          ),
          child: Column(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: style == _ActionStyle.plain ? AppColors.film : fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Invoice list shown when `InvoiceScreen` is opened without a specific
/// invoice (dashboard quick action). Tapping a row opens its detail.
class _InvoiceList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(invoiceListControllerProvider);

    return async.when(
      loading: () => const Center(child: LensLoader()),
      error: (e, _) => ErrorState(
        message: 'Could not load invoices.',
        onRetry: () =>
            ref.read(invoiceListControllerProvider.notifier).refresh(),
      ),
      data: (invoices) {
        if (invoices.isEmpty) {
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () =>
                ref.read(invoiceListControllerProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppColors.filmDim.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'No invoices yet',
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.film,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Open a booking and generate its invoice from the '
                    'event details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.filmDim.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () =>
              ref.read(invoiceListControllerProvider.notifier).refresh(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: invoices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _InvoiceRow(invoice: invoices[i]),
          ),
        );
      },
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (invoice.status.toLowerCase()) {
      'paid' => AppColors.green,
      'sent' => AppColors.gold,
      _ => AppColors.filmDim,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InvoiceScreen(invoice: invoice),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: AppColors.teal,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.packageName.isEmpty
                        ? (invoice.companyName.isEmpty
                              ? 'Invoice'
                              : invoice.companyName)
                        : invoice.packageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.film,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due ${BookingFormat.money(invoice.due, lang: 'en', bnNumerals: false)}',
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 12,
                      color: AppColors.filmDim.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                invoice.status.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

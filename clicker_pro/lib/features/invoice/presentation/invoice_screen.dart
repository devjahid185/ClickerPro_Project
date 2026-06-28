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
import 'package:share_plus/share_plus.dart';

import '../../../theme/app_colors.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/pdf/pdf_export.dart';
import '../../../core/format/booking_format.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../application/invoice_providers.dart';
import '../domain/invoice.dart';

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
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          inv == null ? 'Invoices' : 'Invoice',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: inv == null
          ? _InvoiceList()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyHeader(inv),
                  const SizedBox(height: 24),
                  _buildEventDetails(inv),
                  const SizedBox(height: 16),
                  _buildTeamSection(inv),
                  const SizedBox(height: 16),
                  _buildPaymentSummary(inv),
                  const SizedBox(height: 28),
                  _buildShareButtons(context, inv),
                  const SizedBox(height: 12),
                  _buildPdfExportButton(context, inv),
                ],
              ),
            ),
    );
  }

  Widget _buildCompanyHeader(Invoice inv) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppColors.glassCardDecoration(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.camera_alt,
              color: AppColors.teal,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            inv.companyName.isNotEmpty ? inv.companyName : 'Clicker Pro',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (inv.companyPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              inv.companyPhone,
              style: TextStyle(color: AppColors.filmDim, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventDetails(Invoice inv) {
    return _CardSection(
      title: 'Event Details',
      child: Column(
        children: [
          _detailRow(Icons.receipt_long, 'Package', inv.packageName),
          _detailRow(Icons.flag, 'Status', inv.status.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildTeamSection(Invoice inv) {
    if (inv.teamNames.isEmpty) return const SizedBox.shrink();

    return _CardSection(
      title: 'Team',
      child: Column(
        children: [
          for (var i = 0; i < inv.teamNames.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    i == 0 ? Icons.star_outline : Icons.person_outline,
                    color: i == 0 ? AppColors.gold : AppColors.filmDim,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      inv.teamNames[i],
                      style: TextStyle(
                        color: AppColors.film,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (i < inv.teamPhones.length)
                    Text(
                      inv.teamPhones[i],
                      style: TextStyle(
                        color: AppColors.filmDim,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(Invoice inv) {
    return _CardSection(
      title: 'Payment Summary',
      child: Column(
        children: [
          _paymentRow('Total', inv.total, AppColors.film),
          const SizedBox(height: 6),
          _paymentRow('Advance', inv.advance, AppColors.green),
          const SizedBox(height: 6),
          Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 6),
          _paymentRow(
            'Due',
            inv.due,
            inv.due > 0 ? AppColors.red : AppColors.green,
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, double amount, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.filmDim, fontSize: 14),
        ),
        Text(
          '৳${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.teal, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: AppColors.filmDim, fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: AppColors.film, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButtons(BuildContext context, Invoice inv) {
    final summary = _invoiceText(inv);
    return Row(
      children: [
        Expanded(
          child: _ShareButton(
            icon: Icons.copy_outlined,
            label: 'Copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: summary));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invoice copied to clipboard')),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ShareButton(
            icon: Icons.chat_bubble_outline,
            label: 'WhatsApp',
            color: AppColors.green,
            onTap: () {
              Navigator.of(context).pushNamed(
                RouteNames.whatsappShare,
                arguments: <String, String>{
                  'clientName': '',
                  'clientPhone': '',
                  'eventName': inv.packageName,
                  'eventDate': '',
                  'eventTime': '',
                  'venue': '',
                  'total': '৳${inv.total.toStringAsFixed(0)}',
                  'advance': '৳${inv.advance.toStringAsFixed(0)}',
                  'due': '৳${inv.due.toStringAsFixed(0)}',
                  'packageName': inv.packageName,
                },
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ShareButton(
            icon: Icons.messenger_outline,
            label: 'Messenger',
            color: AppColors.purple,
            // No reliable Messenger deep link for arbitrary text, so open the
            // system share sheet — Messenger (and any other app) shows up there.
            onTap: () => SharePlus.instance.share(ShareParams(text: summary)),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfExportButton(BuildContext context, Invoice inv) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _exportPdf(context, inv),
        icon: Icon(Icons.picture_as_pdf_outlined, color: AppColors.teal),
        label: Text(
          'Export PDF',
          style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.tealGlow),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
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

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.filmDim,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.teal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
                      fontFamily: 'Poppins',
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
                      fontFamily: 'Poppins',
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
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.film,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due ${BookingFormat.money(invoice.due, lang: 'en', bnNumerals: false)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
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
                  fontFamily: 'Poppins',
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

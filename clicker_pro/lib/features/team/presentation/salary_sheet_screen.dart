import 'package:flutter/material.dart';

import '../../../core/pdf/pdf_export.dart';
import '../../../theme/app_colors.dart';
import '../domain/salary_entry.dart';

class SalarySheetScreen extends StatefulWidget {
  const SalarySheetScreen({super.key});

  @override
  State<SalarySheetScreen> createState() => _SalarySheetScreenState();
}

class _SalarySheetScreenState extends State<SalarySheetScreen> {
  late SalarySheet _sheet;
  String _selectedMonth = 'Jun 2026';

  final List<String> _months = [
    'Jan 2026',
    'Feb 2026',
    'Mar 2026',
    'Apr 2026',
    'May 2026',
    'Jun 2026',
  ];

  @override
  void initState() {
    super.initState();
    _sheet = SalarySheet(
      month: _selectedMonth,
      totalEvents: 24,
      totalEarned: 48000,
      totalPaid: 32000,
      totalDue: 16000,
      entries: const [
        SalaryEntry(
          memberId: 'm1',
          memberName: 'Rahim Uddin',
          eventsCount: 8,
          ratePerEvent: 2500,
          totalEarned: 20000,
          totalPaid: 15000,
          totalDue: 5000,
        ),
        SalaryEntry(
          memberId: 'm2',
          memberName: 'Karim Hassan',
          eventsCount: 6,
          ratePerEvent: 2000,
          totalEarned: 12000,
          totalPaid: 12000,
          totalDue: 0,
        ),
        SalaryEntry(
          memberId: 'm3',
          memberName: 'Jamal Ahmed',
          eventsCount: 5,
          ratePerEvent: 3000,
          totalEarned: 15000,
          totalPaid: 5000,
          totalDue: 10000,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Salary Sheet',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.gold,
            ),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthFilter(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _buildSummaryHeader(),
                const SizedBox(height: 20),
                _buildSectionHeader('TEAM MEMBERS'),
                const SizedBox(height: 10),
                ..._sheet.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SalaryMemberCard(entry: entry),
                  ),
                ),
                const SizedBox(height: 20),
                _buildMarkAllPaidButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthFilter() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final month = _months[index];
          final selected = month == _selectedMonth;
          return GestureDetector(
            onTap: () => setState(() => _selectedMonth = month),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.teal.withValues(alpha: 0.15)
                    : AppColors.glass,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppColors.teal.withValues(alpha: 0.30)
                      : AppColors.glassBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                month,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.teal : AppColors.filmDim,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sheet.month.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.filmMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryStat('EVENTS', '${_sheet.totalEvents}', AppColors.teal),
              const SizedBox(width: 16),
              _summaryStat(
                'EARNED',
                _formatMoney(_sheet.totalEarned),
                AppColors.gold,
              ),
              const SizedBox(width: 16),
              _summaryStat(
                'PAID',
                _formatMoney(_sheet.totalPaid),
                AppColors.green,
              ),
              const SizedBox(width: 16),
              _summaryStat(
                'DUE',
                _formatMoney(_sheet.totalDue),
                AppColors.coral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: AppColors.filmMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkAllPaidButton() {
    final hasOutstanding = _sheet.hasOutstanding;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: hasOutstanding ? _markAllPaid : null,
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('Mark All Paid'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          disabledForegroundColor: AppColors.filmMuted,
          side: BorderSide(
            color: hasOutstanding
                ? AppColors.teal.withValues(alpha: 0.30)
                : AppColors.glassBorder,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _markAllPaid() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidLight,
        title: const Text(
          'Mark All Paid',
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          'Mark all ${_sheet.entries.length} members as paid for ${_sheet.month}?',
          style: const TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _sheet = SalarySheet(
                  month: _sheet.month,
                  totalEvents: _sheet.totalEvents,
                  totalEarned: _sheet.totalEarned,
                  totalPaid: _sheet.totalEarned,
                  totalDue: 0,
                  entries: _sheet.entries
                      .map(
                        (e) =>
                            e.copyWith(totalPaid: e.totalEarned, totalDue: 0),
                      )
                      .toList(),
                );
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All members marked as paid'),
                  backgroundColor: AppColors.green,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    String f(double v) => '৳ ${v.toStringAsFixed(0)}';
    try {
      await PdfExporter.share(
        PdfDocumentData(
          documentTitle: 'Salary Sheet',
          fileName: 'salary_${_sheet.month.replaceAll(' ', '_')}',
          subtitle: '${_sheet.month} · ${_sheet.totalEvents} events',
          summary: [
            PdfRow('Total earned', f(_sheet.totalEarned)),
            PdfRow('Total paid', f(_sheet.totalPaid)),
            PdfRow('Total due', f(_sheet.totalDue), emphasize: true),
          ],
          table: _sheet.entries.isEmpty
              ? null
              : PdfTable(
                  headers: const [
                    'Member',
                    'Events',
                    'Earned',
                    'Paid',
                    'Due',
                  ],
                  rows: [
                    for (final e in _sheet.entries)
                      [
                        e.memberName,
                        e.eventsCount.toString(),
                        f(e.totalEarned),
                        f(e.totalPaid),
                        f(e.totalDue),
                      ],
                  ],
                ),
          footnote: 'Generated by Clicker Pro',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('PDF তৈরি করা যায়নি: $e')),
      );
    }
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.filmMuted,
      ),
    );
  }
}

class _SalaryMemberCard extends StatelessWidget {
  const _SalaryMemberCard({required this.entry});
  final SalaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPaid = entry.isFullyPaid;
    final statusColor = isPaid ? AppColors.green : AppColors.coral;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                child: Text(
                  entry.memberName.isNotEmpty
                      ? entry.memberName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.memberName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.film,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.eventsCount} events · ${_formatRate(entry.ratePerEvent)}/event',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.filmDim.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'DUE',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
          const SizedBox(height: 10),
          Row(
            children: [
              _metric(
                'Earned',
                _formatMoney(entry.totalEarned),
                AppColors.gold,
              ),
              const SizedBox(width: 16),
              _metric('Paid', _formatMoney(entry.totalPaid), AppColors.green),
              const Spacer(),
              if (!isPaid)
                _metric('Due', _formatMoney(entry.totalDue), AppColors.coral),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            color: AppColors.filmMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatRate(double rate) {
    if (rate >= 1000) {
      return '${(rate / 1000).toStringAsFixed(rate % 1000 == 0 ? 0 : 1)}K';
    }
    return rate.toStringAsFixed(0);
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

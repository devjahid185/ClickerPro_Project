import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pdf/pdf_export.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/team_providers.dart';
import '../domain/salary_entry.dart';
import '../domain/team_member.dart';

class SalarySheetScreen extends ConsumerStatefulWidget {
  const SalarySheetScreen({super.key});

  @override
  ConsumerState<SalarySheetScreen> createState() => _SalarySheetScreenState();
}

class _SalarySheetScreenState extends ConsumerState<SalarySheetScreen> {
  SalarySheet? _sheet;
  String _selectedMonth = _currentMonthLabel();

  static String _currentMonthLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  List<String> get _months {
    final now = DateTime.now();
    const mNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i, 1);
      return '${mNames[d.month - 1]} ${d.year}';
    });
  }

  SalarySheet _buildSheet(List<TeamMember> members, String month) {
    if (members.isEmpty) {
      return SalarySheet(
        month: month,
        totalEvents: 0,
        totalEarned: 0,
        totalPaid: 0,
        totalDue: 0,
        entries: const [],
      );
    }
    // Placeholder per-member data until payout API is wired.
    final entries = members.map((m) {
      return SalaryEntry(
        memberId: m.userId,
        memberName: m.fullName.isNotEmpty ? m.fullName : m.email,
        eventsCount: 0,
        ratePerEvent: 0,
        totalEarned: 0,
        totalPaid: 0,
        totalDue: 0,
      );
    }).toList();
    return SalarySheet(
      month: month,
      totalEvents: 0,
      totalEarned: 0,
      totalPaid: 0,
      totalDue: 0,
      entries: entries,
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider);

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
            onPressed: _sheet != null ? _exportPdf : null,
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: LensLoader()),
        error: (_, _) => const Center(
          child: EmptyState(
            icon: Icons.people_outline,
            message: 'Could not load team members.',
          ),
        ),
        data: (members) {
          final sheet = _sheet ?? _buildSheet(members, _selectedMonth);
          if (_sheet == null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _sheet = sheet),
            );
          }
          return Column(
            children: [
              _buildMonthFilter(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    _buildSummaryHeader(sheet),
                    const SizedBox(height: 20),
                    _buildSectionHeader('TEAM MEMBERS'),
                    const SizedBox(height: 10),
                    if (sheet.entries.isEmpty)
                      const EmptyState(
                        icon: Icons.people_outline,
                        message: 'No team members yet.',
                      )
                    else
                      ...sheet.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SalaryMemberCard(entry: entry),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (sheet.entries.isNotEmpty) _buildMarkAllPaidButton(sheet),
                  ],
                ),
              ),
            ],
          );
        },
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

  Widget _buildSummaryHeader(SalarySheet sheet) {
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
            sheet.month.toUpperCase(),
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
              _summaryStat('EVENTS', '${sheet.totalEvents}', AppColors.teal),
              const SizedBox(width: 16),
              _summaryStat(
                'EARNED',
                _formatMoney(sheet.totalEarned),
                AppColors.gold,
              ),
              const SizedBox(width: 16),
              _summaryStat(
                'PAID',
                _formatMoney(sheet.totalPaid),
                AppColors.green,
              ),
              const SizedBox(width: 16),
              _summaryStat(
                'DUE',
                _formatMoney(sheet.totalDue),
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

  Widget _buildMarkAllPaidButton(SalarySheet sheet) {
    final hasOutstanding = sheet.hasOutstanding;
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
    final sheet = _sheet;
    if (sheet == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidLight,
        title: const Text(
          'Mark All Paid',
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          'Mark all ${sheet.entries.length} members as paid for ${sheet.month}?',
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
                  month: sheet.month,
                  totalEvents: sheet.totalEvents,
                  totalEarned: sheet.totalEarned,
                  totalPaid: sheet.totalEarned,
                  totalDue: 0,
                  entries: sheet.entries
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
    final sheet = _sheet;
    if (sheet == null) return;
    final messenger = ScaffoldMessenger.of(context);
    String f(double v) => '৳ ${v.toStringAsFixed(0)}';
    try {
      await PdfExporter.share(
        PdfDocumentData(
          documentTitle: 'Salary Sheet',
          fileName: 'salary_${sheet.month.replaceAll(' ', '_')}',
          subtitle: '${sheet.month} · ${sheet.totalEvents} events',
          summary: [
            PdfRow('Total earned', f(sheet.totalEarned)),
            PdfRow('Total paid', f(sheet.totalPaid)),
            PdfRow('Total due', f(sheet.totalDue), emphasize: true),
          ],
          table: sheet.entries.isEmpty
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
                    for (final e in sheet.entries)
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

// lib/features/freelancer/presentation/fl_companies_screen.dart
//
// Freelancer → "My Companies" (Bug #2).
//
// Lists every studio/company the freelancer is currently attached to, with a
// quick read of how much work + money each relationship holds. Data is the
// per-owner breakdown already returned by the earnings overview, so this
// screen adds no new network surface — it reuses
// `flEarningOverviewControllerProvider`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/booking_format.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/fl_earning_providers.dart';
import '../domain/fl_earning.dart';

class FlCompaniesScreen extends ConsumerWidget {
  const FlCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(flEarningOverviewControllerProvider);

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
          'My Companies',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (e, _) => ErrorState(
          message: 'Could not load your companies.',
          onRetry: () => ref
              .read(flEarningOverviewControllerProvider.notifier)
              .refresh(),
        ),
        data: (overview) => RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref
              .read(flEarningOverviewControllerProvider.notifier)
              .refresh(),
          child: overview.owners.isEmpty
              ? _emptyState(context)
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: overview.owners.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${overview.owners.length} '
                          '${overview.owners.length == 1 ? "studio" : "studios"} '
                          'you work with',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.filmDim,
                          ),
                        ),
                      );
                    }
                    return _CompanyCard(owner: overview.owners[i - 1]);
                  },
                ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.business_outlined,
          size: 48,
          color: AppColors.filmDim.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No companies yet',
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
            'When a studio adds you to their team with a passcode, it will '
            'show up here.',
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
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.owner});

  final FlOwnerEarning owner;

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business_rounded,
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
                      owner.ownerName.isEmpty ? 'Studio' : owner.ownerName,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.film,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${owner.eventsCount} '
                      '${owner.eventsCount == 1 ? "event" : "events"}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.filmDim.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.line(0.06)),
          const SizedBox(height: 10),
          Row(
            children: [
              _metric(
                'Earned',
                BookingFormat.money(
                  owner.earnedAmount,
                  lang: 'en',
                  bnNumerals: false,
                ),
                AppColors.green,
              ),
              const SizedBox(width: 16),
              _metric(
                'Due',
                BookingFormat.money(
                  owner.pendingAmount,
                  lang: 'en',
                  bnNumerals: false,
                ),
                AppColors.coral,
              ),
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
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.filmDim.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

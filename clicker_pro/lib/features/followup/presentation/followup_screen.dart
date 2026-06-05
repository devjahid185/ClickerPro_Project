import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../domain/followup.dart';

final followupListProvider = StateProvider<List<Followup>>(
  (ref) => <Followup>[],
);

class FollowupScreen extends ConsumerWidget {
  const FollowupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(followupListProvider);

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
          'Client Follow-up',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.follow_the_signs_outlined,
                  message: 'No follow-ups scheduled',
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final f = items[i];
                return _FollowupRow(
                  followup: f,
                  onToggle: () {
                    ref.read(followupListProvider.notifier).state = [
                      for (final item in items)
                        if (item.id == f.id)
                          item.copyWith(completed: !item.completed)
                        else
                          item,
                    ];
                  },
                );
              },
            ),
    );
  }
}

class _FollowupRow extends StatelessWidget {
  const _FollowupRow({required this.followup, required this.onToggle});

  final Followup followup;
  final VoidCallback onToggle;

  IconData _typeIcon() {
    switch (followup.type) {
      case FollowupType.album:
        return Icons.photo_library_outlined;
      case FollowupType.payment:
        return Icons.payment_outlined;
      case FollowupType.feedback:
        return Icons.rate_review_outlined;
    }
  }

  Color _typeColor() {
    switch (followup.type) {
      case FollowupType.album:
        return AppColors.teal;
      case FollowupType.payment:
        return AppColors.gold;
      case FollowupType.feedback:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor();
    final dateStr =
        '${followup.scheduledDate.year}-'
        '${followup.scheduledDate.month.toString().padLeft(2, '0')}-'
        '${followup.scheduledDate.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppColors.glassCardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: AppColors.iconWrapDecoration(
            typeColor.withValues(alpha: 0.15),
          ),
          child: Icon(_typeIcon(), color: typeColor, size: 20),
        ),
        title: Text(
          followup.type.name[0].toUpperCase() + followup.type.name.substring(1),
          style: const TextStyle(
            color: AppColors.film,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Booking: ${followup.bookingId} \u00b7 $dateStr',
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
        trailing: GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: followup.completed
                  ? AppColors.green.withValues(alpha: 0.15)
                  : AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              followup.completed ? 'Done' : 'Pending',
              style: TextStyle(
                color: followup.completed ? AppColors.green : AppColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../data/followup_repository.dart';
import '../domain/followup.dart';

// ─── Followup Notifier ────────────────────────────────────────────────────────
//
// Thin notifier over FollowupRepository (data layer owns API + cache).

final followupRepositoryProvider = Provider<FollowupRepository>(
  (ref) => FollowupRepository(ref.read(apiClientProvider)),
);

class _FollowupNotifier extends AsyncNotifier<List<Followup>> {
  FollowupRepository get _repo => ref.read(followupRepositoryProvider);

  @override
  Future<List<Followup>> build() => _repo.list();

  Future<void> add(Followup f) async {
    final created = await _repo.create(f);
    final current = state.valueOrNull ?? <Followup>[];
    final next = <Followup>[...current, created];
    state = AsyncData(next);
    await _repo.saveCache(next);
  }

  Future<void> toggle(String id) async {
    final current = state.valueOrNull ?? <Followup>[];
    final matches = current.where((e) => e.id == id);
    if (matches.isEmpty) return;
    final target = matches.first;
    await _repo.setCompleted(id, !target.completed);
    final next = <Followup>[
      for (final item in current)
        if (item.id == id) item.copyWith(completed: !item.completed) else item,
    ];
    state = AsyncData(next);
    await _repo.saveCache(next);
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    final current = state.valueOrNull ?? <Followup>[];
    final next = <Followup>[for (final item in current) if (item.id != id) item];
    state = AsyncData(next);
    await _repo.saveCache(next);
  }
}

final followupListProvider =
    AsyncNotifierProvider<_FollowupNotifier, List<Followup>>(
      _FollowupNotifier.new,
    );

class FollowupScreen extends ConsumerWidget {
  const FollowupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(followupListProvider);

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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Follow-up',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (_, _) => const Center(
          child: EmptyState(
            icon: Icons.follow_the_signs_outlined,
            message: 'Could not load follow-ups.',
          ),
        ),
        data: (items) => items.isEmpty
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
                    onToggle: () =>
                        ref.read(followupListProvider.notifier).toggle(f.id),
                    onDelete: () =>
                        ref.read(followupListProvider.notifier).remove(f.id),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Followup>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddFollowupSheet(),
    );
    if (result != null) {
      await ref.read(followupListProvider.notifier).add(result);
    }
  }
}

// ─── Add Follow-up Bottom Sheet ───────────────────────────────────────────────

class _AddFollowupSheet extends StatefulWidget {
  const _AddFollowupSheet();

  @override
  State<_AddFollowupSheet> createState() => _AddFollowupSheetState();
}

class _AddFollowupSheetState extends State<_AddFollowupSheet> {
  final _bookingCtrl = TextEditingController();
  FollowupType _type = FollowupType.feedback;
  DateTime _date = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _bookingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.voidElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.glassBorder),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'New Follow-up',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bookingCtrl,
            style: const TextStyle(color: AppColors.film),
            decoration: InputDecoration(
              labelText: 'Booking ID / Client Name',
              labelStyle: TextStyle(color: AppColors.filmDim),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Type',
            style: TextStyle(
              color: AppColors.filmDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: FollowupType.values
                .map(
                  (t) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == t
                                ? AppColors.orange.withValues(alpha: 0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _type == t
                                  ? AppColors.orange
                                  : AppColors.glassBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            t.name[0].toUpperCase() + t.name.substring(1),
                            style: TextStyle(
                              color: _type == t
                                  ? AppColors.orange
                                  : AppColors.filmDim,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.teal,
              size: 20,
            ),
            title: Text(
              'Scheduled: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.film, fontSize: 14),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.orange,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final bookingId = _bookingCtrl.text.trim();
                if (bookingId.isEmpty) return;
                Navigator.of(context).pop(
                  Followup(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    bookingId: bookingId,
                    type: _type,
                    scheduledDate: _date,
                  ),
                );
              },
              child: const Text(
                'Add Follow-up',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowupRow extends StatelessWidget {
  const _FollowupRow({
    required this.followup,
    required this.onToggle,
    required this.onDelete,
  });

  final Followup followup;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
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
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: AppColors.filmMuted, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

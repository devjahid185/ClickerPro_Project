// lib/features/admin/presentation/admin_user_list_screen.dart
//
// Drill-down from a Stats tab tile (Total Users / Studio Owners /
// Freelancers / Admins) — read-only list of matching accounts. No
// booking/finance data is fetched or shown (see AdminController PRIVACY
// comments); only the non-financial `AdminUser` fields are rendered.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/admin_providers.dart';
import '../domain/admin_user.dart';

class AdminUserListScreen extends ConsumerStatefulWidget {
  const AdminUserListScreen({super.key, required this.title, required this.role});

  final String title;
  final String? role;

  @override
  ConsumerState<AdminUserListScreen> createState() =>
      _AdminUserListScreenState();
}

class _AdminUserListScreenState extends ConsumerState<AdminUserListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Case-insensitive match across the fields an admin would search by:
  /// name, email, business name and phone.
  bool _matches(AdminUser u, String q) {
    if (q.isEmpty) return true;
    final hay = [
      u.fullName,
      u.email,
      u.businessName ?? '',
      u.phone ?? '',
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final async = ref.watch(adminUsersProvider(role));
    final q = _query.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: AppColors.film, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search name, email, phone, business…',
                hintStyle: TextStyle(color: AppColors.filmDim, fontSize: 13.5),
                prefixIcon: Icon(Icons.search, color: AppColors.filmDim, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close, color: AppColors.filmDim, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.line(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.line(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.orange),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(adminUsersProvider(role).future),
              child: async.when(
                loading: () => const Center(child: LensLoader()),
                error: (err, _) => ListView(
                  children: [
                    const SizedBox(height: 120),
                    ErrorState(
                      message: 'Failed to load users',
                      onRetry: () => ref.invalidate(adminUsersProvider(role)),
                    ),
                  ],
                ),
                data: (users) {
                  final filtered = [
                    for (final u in users)
                      if (_matches(u, q)) u,
                  ];
                  if (filtered.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.people_outline,
                          message: q.isEmpty
                              ? 'No accounts found.'
                              : 'No accounts match “${_query.trim()}”.',
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _UserCard(user: filtered[i], listRole: role),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user, required this.listRole});
  final AdminUser user;

  /// The role filter of the parent list — needed to invalidate the right
  /// provider after an action changes this user.
  final String? listRole;

  void _openActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UserActionSheet(user: user, listRole: listRole),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openActions(context, ref),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line(0.08)),
          ),
          child: _cardBody(),
        ),
      ),
    );
  }

  Widget _cardBody() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  user.fullName.isEmpty ? user.email : user.fullName,
                  style: TextStyle(
                    fontFamily: AppText.brandFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: AppColors.film,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: (user.isActive ? AppColors.teal : Colors.redAccent)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.isActive ? user.role : 'SUSPENDED',
                  style: TextStyle(
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: user.isActive ? AppColors.teal : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: TextStyle(color: AppColors.filmDim, fontSize: 13),
          ),
          if (user.businessName != null) ...[
            const SizedBox(height: 2),
            Text(
              user.businessName!,
              style: TextStyle(color: AppColors.filmDim, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 14, color: AppColors.filmDim),
              const SizedBox(width: 4),
              Text(
                '${user.totalEvents} events',
                style: TextStyle(color: AppColors.filmDim, fontSize: 12),
              ),
              if (user.plan != null) ...[
                const SizedBox(width: 14),
                Icon(Icons.workspace_premium_outlined, size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  user.plan!,
                  style: TextStyle(color: AppColors.filmDim, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      );
  }
}

class _UserActionSheet extends ConsumerStatefulWidget {
  const _UserActionSheet({required this.user, required this.listRole});
  final AdminUser user;
  final String? listRole;

  @override
  ConsumerState<_UserActionSheet> createState() => _UserActionSheetState();
}

class _UserActionSheetState extends ConsumerState<_UserActionSheet> {
  static const _roles = ['OWNER', 'FREELANCER', 'BOTH', 'MANAGER', 'ADMIN'];
  static const _plans = ['FREE', 'PRO'];

  late String _role;
  late String _plan;
  late bool _active;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _role = _roles.contains(widget.user.role) ? widget.user.role : 'OWNER';
    _plan = _plans.contains(widget.user.plan) ? widget.user.plan! : 'FREE';
    _active = widget.user.isActive;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      ref.invalidate(adminUsersProvider(widget.listRole));
      ref.invalidate(adminStatsProvider);
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not save — please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.read(adminApiProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.user.fullName.isEmpty ? widget.user.email : widget.user.fullName,
              style: TextStyle(
                fontFamily: AppText.brandFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.film,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.user.email,
              style: TextStyle(color: AppColors.filmDim, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Text('Role', style: TextStyle(color: AppColors.filmDim, fontSize: 12.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roles.map((r) {
                final selected = r == _role;
                return ChoiceChip(
                  label: Text(r),
                  selected: selected,
                  onSelected: _busy
                      ? null
                      : (_) {
                          setState(() => _role = r);
                          _run(() => api.setUserRole(widget.user.id, r));
                        },
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 18),
            Text('Plan', style: TextStyle(color: AppColors.filmDim, fontSize: 12.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _plans.map((p) {
                final selected = p == _plan;
                return ChoiceChip(
                  label: Text(p),
                  selected: selected,
                  onSelected: _busy
                      ? null
                      : (_) {
                          setState(() => _plan = p);
                          _run(() => api.setUserPlan(widget.user.id, p));
                        },
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _active ? 'Account Active' : 'Account Suspended',
                style: TextStyle(
                  color: _active ? AppColors.film : Colors.redAccent,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _active
                    ? 'Turn off to suspend this account'
                    : 'Turn on to reactivate this account',
                style: TextStyle(color: AppColors.filmDim, fontSize: 12),
              ),
              value: _active,
              activeThumbColor: AppColors.orange,
              onChanged: _busy
                  ? null
                  : (v) {
                      setState(() => _active = v);
                      _run(() => api.setUserSuspended(widget.user.id, !v));
                    },
            ),
            if (_busy) ...[
              const SizedBox(height: 8),
              const Center(child: LensLoader(size: 22)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }
}

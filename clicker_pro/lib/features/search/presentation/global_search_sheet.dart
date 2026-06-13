// lib/features/search/presentation/global_search_sheet.dart
//
// Live global-search bottom sheet opened from the dashboard topbar 🔍.
// Types are debounced, queried against `GET /api/search/global`, and the
// flattened hits are shown grouped by icon. Tapping a booking/client jumps
// to the relevant screen.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/providers.dart';
import '../../../theme/app_colors.dart';
import '../../bookings/application/booking_providers.dart';
import '../data/search_api.dart';

final searchApiProvider = Provider<SearchApi>(
  (ref) => SearchApi(ref.read(apiClientProvider)),
);

class GlobalSearchSheet extends ConsumerStatefulWidget {
  const GlobalSearchSheet({super.key});

  @override
  ConsumerState<GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends ConsumerState<GlobalSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<SearchHit> _hits = const [];
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(value));
  }

  Future<void> _run(String query) async {
    final q = query.trim();
    _lastQuery = q;
    if (q.isEmpty) {
      setState(() {
        _hits = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hits = await ref.read(searchApiProvider).search(q);
      // Ignore stale responses if the query moved on.
      if (!mounted || q != _lastQuery) return;
      setState(() {
        _hits = hits;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || q != _lastQuery) return;
      setState(() {
        _loading = false;
        _error = 'Search failed. Check your connection.';
      });
    }
  }

  Future<void> _openHit(SearchHit hit) async {
    final navigator = Navigator.of(context);

    // Bookings: the search API returns the SERVER id, but the detail
    // screen is keyed by the local Drift id — resolve it first so the
    // tap actually opens Event Details (the old behaviour dumped the
    // user on the list, which read as "search doesn't work").
    if (hit.kind == SearchKind.booking) {
      try {
        final booking = await ref
            .read(bookingRepositoryProvider)
            .getByRemoteId(hit.id);
        if (!mounted) return;
        navigator.pop();
        if (booking != null) {
          navigator.pushNamed(RouteNames.bookingDetail, arguments: booking.id);
        } else {
          // Not synced locally yet — the list is the best we can do.
          navigator.pushNamed(RouteNames.bookings);
        }
      } catch (_) {
        if (!mounted) return;
        navigator.pop();
        navigator.pushNamed(RouteNames.bookings);
      }
      return;
    }

    navigator.pop();
    final route = switch (hit.kind) {
      SearchKind.member => RouteNames.team,
      SearchKind.package => RouteNames.packages,
      SearchKind.booking || SearchKind.client => RouteNames.bookings,
    };
    navigator.pushNamed(route);
  }

  IconData _iconFor(SearchKind kind) => switch (kind) {
        SearchKind.booking => Icons.event_note_rounded,
        SearchKind.client => Icons.person_rounded,
        SearchKind.member => Icons.groups_rounded,
        SearchKind.package => Icons.inventory_2_rounded,
      };

  Color _colorFor(SearchKind kind) => switch (kind) {
        SearchKind.booking => AppColors.indigo,
        SearchKind.client => AppColors.accent,
        SearchKind.member => AppColors.green,
        SearchKind.package => AppColors.gold,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: _run,
              style: TextStyle(color: AppColors.film),
              decoration: InputDecoration(
                hintText: 'Search bookings, clients, team, packages…',
                hintStyle: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(Icons.search, color: AppColors.filmDim),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.red),
        ),
      );
    }
    if (_controller.text.trim().isEmpty) {
      return _hint('Start typing to search across your studio.');
    }
    if (_hits.isEmpty) {
      return _hint('No matches for “${_controller.text.trim()}”.');
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _hits.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: Colors.black.withValues(alpha: 0.05),
      ),
      itemBuilder: (_, i) {
        final hit = _hits[i];
        final color = _colorFor(hit.kind);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(hit.kind), color: color, size: 20),
          ),
          title: Text(
            hit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.film,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: hit.subtitle.isEmpty
              ? null
              : Text(
                  hit.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
          onTap: () => _openHit(hit),
        );
      },
    );
  }

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.filmDim.withValues(alpha: 0.85)),
        ),
      );
}

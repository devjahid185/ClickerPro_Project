// lib/features/public_booking/presentation/pending_public_bookings_screen.dart
//
// Owner / Both inbox of public-booking submissions awaiting decision.
// Streams the local Drift mirror, kicks a background `refreshPending`
// on first frame so the list reflects the server, and exposes per-row
// Approve / Reject actions.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Public Booking Approval". Validates Requirements 6.6–6.10, 11.6.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format/booking_format.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/role/capability.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../shared/widgets/web_form_kit.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/web_theme.dart';
import '../../bookings/application/booking_providers.dart';
import '../../profile/application/profile_controllers.dart';
import '../application/public_booking_providers.dart';
import '../domain/public_booking_request.dart';
import '../../../theme/app_theme.dart';

class PendingPublicBookingsScreen extends ConsumerStatefulWidget {
  const PendingPublicBookingsScreen({super.key});

  @override
  ConsumerState<PendingPublicBookingsScreen> createState() =>
      _PendingPublicBookingsScreenState();
}

class _PendingPublicBookingsScreenState
    extends ConsumerState<PendingPublicBookingsScreen> {
  /// Issued once per visit for the dark public-link bar (web only).
  Future<({String url, String token, DateTime expiresAt})>? _linkFuture;

  @override
  void initState() {
    super.initState();
    // Background-refresh on mount so the local mirror is fresh. We
    // deliberately don't await — the StreamProvider will pick up new
    // rows as they land.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: discarded_futures
      ref.read(publicBookingRepositoryProvider).refreshPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(bookingsPolicyProvider);
    final pendingAsync = ref.watch(pendingPublicBookingsProvider);

    // Sunset Studio web-native Self-Booking (handoff Screen 12): dark public
    // link bar, client form preview + approval queue. Mobile unchanged.
    final webWide = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    if (webWide) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildWebBody(context, policy, pendingAsync),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Pending requests',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: !policy.can(Capability.approvePublicBooking)
                  ? Center(
                      child: ErrorState(
                        message:
                            'You do not have permission to view this list.',
                        onRetry: () => Navigator.of(context).maybePop(),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.orange,
                      backgroundColor: AppColors.surface,
                      onRefresh: () => ref
                          .read(publicBookingRepositoryProvider)
                          .refreshPending(),
                      child: pendingAsync.when(
                        loading: () =>
                            const _ScrollableSlot(child: LensLoader()),
                        error: (err, _) => _ScrollableSlot(
                          child: ErrorState(
                            message: 'Could not load pending requests.',
                            onRetry: () =>
                                ref.invalidate(pendingPublicBookingsProvider),
                          ),
                        ),
                        data: (rows) => rows.isEmpty
                            ? const _ScrollableSlot(
                                child: EmptyState(
                                  icon: Icons.inbox_outlined,
                                  message: 'No pending requests right now.',
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  24,
                                ),
                                itemCount: rows.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) => _RequestRow(
                                  request: rows[i],
                                  onApprove: () => _onApprove(rows[i]),
                                  onReject: () => _onReject(rows[i]),
                                ),
                              ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onApprove(PublicBookingRequest req) async {
    try {
      final booking = await ref
          .read(publicBookingRepositoryProvider)
          .approve(req.id, policy: ref.read(bookingsPolicyProvider));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approved · ${booking.title}')));
      // Drop into the new booking's detail screen so the user can
      // start filling in payment / assignments etc.
      Navigator.of(
        context,
      ).pushReplacementNamed(RouteNames.bookingDetail, arguments: booking.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
    }
  }

  Future<void> _onReject(PublicBookingRequest req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Reject request?',
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          'The request will be removed from the pending list.',
          style: TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(publicBookingRepositoryProvider)
          .reject(req.id, policy: ref.read(bookingsPolicyProvider));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request rejected.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
    }
  }

  // ─────────────────────────────────────────────── WEB (Sunset Studio)

  Widget _buildWebBody(
    BuildContext context,
    dynamic policy,
    AsyncValue<List<PublicBookingRequest>> pendingAsync,
  ) {
    if (!(policy.can(Capability.approvePublicBooking) as bool)) {
      return Center(
        child: ErrorState(
          message: 'You do not have permission to view this list.',
          onRetry: () => Navigator.of(context).maybePop(),
        ),
      );
    }
    _linkFuture ??= ref.read(publicBookingRepositoryProvider).issueToken(
          policy: ref.read(bookingsPolicyProvider),
        );

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () =>
          ref.read(publicBookingRepositoryProvider).refreshPending(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 64),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: WebStagger(
              children: [
                const OfflineBanner(),
                WebBackLink(
                  label: '← Back to Bookings',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 16),
                _webLinkBar(context),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final preview = _webFormPreview();
                    final queue = _webQueue(context, pendingAsync);
                    if (constraints.maxWidth < 880) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          preview,
                          const SizedBox(height: 16),
                          queue,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 10, child: preview),
                        const SizedBox(width: 16),
                        Expanded(flex: 12, child: queue),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dark public-link bar: gold label · frosted mono link · COPY / WHATSAPP.
  Widget _webLinkBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: BoxDecoration(
        color: WebTheme.chrome,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        boxShadow: WebTheme.darkCardShadow,
      ),
      child: FutureBuilder<({String url, String token, DateTime expiresAt})>(
        future: _linkFuture,
        builder: (context, snap) {
          final ready = snap.hasData && snap.data!.token.trim().isNotEmpty;
          final url = ready ? snap.data!.url : null;
          final statusText = snap.hasError
              ? 'Could not fetch the link — pull to refresh.'
              : (snap.hasData
                  ? 'Your booking link isn\'t ready yet — sign out and back '
                      'in, then try again.'
                  : 'Fetching your public link…');
          return Row(
            children: [
              Text(
                '🔗 PUBLIC LINK',
                style: WebTheme.label(
                  size: 9.5,
                  color: WebTheme.amber,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFF6EE),
                    borderRadius: BorderRadius.circular(WebTheme.rButton),
                    border: Border.all(color: WebTheme.chromeLine),
                  ),
                  child: Text(
                    url ?? statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: WebTheme.mono,
                      fontSize: 12,
                      color: url != null
                          ? WebTheme.chromeInk
                          : WebTheme.chromeInkMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              WebTintButton(
                label: 'COPY',
                mono: true,
                fontSize: 9,
                accent: WebTheme.amber,
                tint: const Color(0x26F5B02E),
                tintBorder: const Color(0x59F5B02E),
                textColor: WebTheme.amber,
                onTap: () {
                  if (url == null) return;
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied ✓')),
                  );
                },
              ),
              const SizedBox(width: 8),
              WebTintButton(
                label: 'WHATSAPP',
                mono: true,
                fontSize: 9,
                accent: WebTheme.success,
                tint: const Color(0x261E9E6A),
                tintBorder: const Color(0x591E9E6A),
                textColor: const Color(0xFF6FD3A8),
                onTap: () {
                  if (url == null) return;
                  launchUrl(
                    Uri.parse(
                      'https://wa.me/?text=${Uri.encodeComponent('Fill in your details at this link to book our studio:\n$url')}',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Static "what clients see" preview of the public booking form.
  Widget _webFormPreview() {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final studioName = (me?.companyName?.trim().isNotEmpty ?? false)
        ? me!.companyName!.trim()
        : (me?.name ?? 'Your Studio');

    Widget fakeInput(String placeholder, {IconData? icon, int lines = 1}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: WebTheme.pageBg,
          borderRadius: BorderRadius.circular(WebTheme.rButton),
          border: Border.all(color: WebTheme.hairline),
        ),
        child: Row(
          crossAxisAlignment:
              lines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: WebTheme.orange),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Text(
                placeholder,
                maxLines: lines,
                style:
                    WebTheme.bodyStyle(size: 12.5, color: WebTheme.inkFaint),
              ),
            ),
          ],
        ),
      );
    }

    Widget chip(String label, {bool selected = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? WebTheme.orange : WebTheme.pageBg,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          border: Border.all(
            color: selected ? WebTheme.orange : WebTheme.hairline,
          ),
        ),
        child: Text(
          label,
          style: WebTheme.bodyStyle(
            size: 11.5,
            color: selected ? WebTheme.chromeInk : WebTheme.inkSoft,
            weight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'WHAT CLIENTS SEE',
            style: WebTheme.label(size: 10, color: WebTheme.inkMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: WebTheme.sunset,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  studioName.isEmpty ? 'G' : studioName[0].toUpperCase(),
                  style: WebTheme.displayStyle(
                    size: 16,
                    color: WebTheme.chromeInk,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  studioName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WebTheme.displayStyle(
                      size: 15, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          fakeInput('Your name'),
          fakeInput('Phone'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip('Wedding', selected: true),
              chip('Holud'),
              chip('Reception'),
              chip('Corporate'),
              chip('Birthday'),
            ],
          ),
          const SizedBox(height: 12),
          fakeInput('Preferred date', icon: Icons.calendar_month_rounded),
          fakeInput('Anything we should know? (optional)', lines: 2),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: WebTheme.sunset,
              borderRadius: BorderRadius.circular(WebTheme.rFull),
              boxShadow: WebTheme.buttonGlow,
            ),
            child: Text(
              'Request Booking',
              style: WebTheme.bodyStyle(
                size: 13,
                color: WebTheme.chromeInk,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'POWERED BY GRAPHY7',
              style: WebTheme.label(size: 8, color: WebTheme.inkFaint),
            ),
          ),
        ],
      ),
    );
  }

  /// Approval queue — request cards with gold left border + real actions.
  Widget _webQueue(
    BuildContext context,
    AsyncValue<List<PublicBookingRequest>> pendingAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'APPROVAL QUEUE',
                  style: WebTheme.label(size: 10, color: WebTheme.inkMuted),
                ),
              ),
              pendingAsync.maybeWhen(
                data: (rows) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: WebTheme.amberTint,
                    borderRadius: BorderRadius.circular(WebTheme.rFull),
                    border: Border.all(color: WebTheme.amberTintBorder),
                  ),
                  child: Text(
                    '${rows.length} PENDING',
                    style: WebTheme.label(
                      size: 8.5,
                      color: WebTheme.amberText,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          pendingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: LensLoader()),
            ),
            error: (err, _) => ErrorState(
              message: 'Could not load pending requests.',
              onRetry: () => ref.invalidate(pendingPublicBookingsProvider),
            ),
            data: (rows) => rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'No pending requests right now.',
                        style: WebTheme.bodyStyle(
                            size: 13, color: WebTheme.inkMuted),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final req in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _webRequestCard(context, req),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _webRequestCard(BuildContext context, PublicBookingRequest req) {
    final shiftLabel = switch (req.shift.name) {
      'day' => 'Day',
      'night' => 'Night',
      _ => 'Full Day',
    };
    final phone = req.clientPhone.trim();
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: WebTheme.pageBg,
        borderRadius: BorderRadius.circular(WebTheme.rTile),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold left rule (the handoff's 3px accent).
          Container(
            width: 3,
            height: 88,
            decoration: BoxDecoration(
              color: WebTheme.amber,
              borderRadius: BorderRadius.circular(WebTheme.rFull),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WebTheme.amberTint,
              shape: BoxShape.circle,
              border: Border.all(color: WebTheme.amberTintBorder),
            ),
            child: Text(
              req.clientName.isEmpty ? '?' : req.clientName[0].toUpperCase(),
              style: WebTheme.displayStyle(
                size: 14,
                color: WebTheme.amberText,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      WebTheme.bodyStyle(size: 13.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${req.title} · '
                  '${DateFormat('d MMM yyyy').format(req.date)} · $shiftLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WebTheme.bodyStyle(
                      size: 11.5, color: WebTheme.inkMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  phone,
                  style: TextStyle(
                    fontFamily: WebTheme.mono,
                    fontSize: 11,
                    color: WebTheme.inkSoft,
                  ),
                ),
                if ((req.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: WebTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WebTheme.innerLine),
                    ),
                    child: Text(
                      '“${req.notes!}”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WebTheme.bodyStyle(
                        size: 11.5,
                        color: WebTheme.inkSoft,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    WebTintButton(
                      label: '✓ Approve → Booking',
                      accent: WebTheme.success,
                      tint: WebTheme.successTint,
                      tintBorder: WebTheme.successTintBorder,
                      onTap: () => _onApprove(req),
                    ),
                    const SizedBox(width: 8),
                    WebTintButton(
                      label: '✕ Reject',
                      accent: WebTheme.danger,
                      tint: WebTheme.dangerTint,
                      tintBorder: WebTheme.dangerTintBorder,
                      onTap: () => _onReject(req),
                    ),
                    const Spacer(),
                    if (digits.isNotEmpty)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => launchUrl(Uri.parse('tel:$digits')),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: WebTheme.successTint,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color: WebTheme.successTintBorder),
                            ),
                            child: const Icon(Icons.call_outlined,
                                size: 15, color: WebTheme.success),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final PublicBookingRequest request;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${DateFormat.yMMMEd().format(request.date)} · '
            '${BookingFormat.clockRange(request.startTime, request.endTime, separator: '–')}',
            style: TextStyle(
              color: AppColors.filmDim,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: AppColors.filmMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${request.clientName} · ${request.clientPhone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.film, fontSize: 12.5),
                ),
              ),
            ],
          ),
          if ((request.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              request.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.film.withValues(alpha: 0.85),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.red,
                    size: 16,
                  ),
                  label: Text(
                    'Reject',
                    style: TextStyle(color: AppColors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.red.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => onReject(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => onApprove(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrollableSlot extends StatelessWidget {
  const _ScrollableSlot({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(child: child),
        ),
      ],
    );
  }
}

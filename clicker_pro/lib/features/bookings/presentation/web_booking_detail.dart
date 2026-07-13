// lib/features/bookings/presentation/web_booking_detail.dart
//
// WEB-ONLY Event Details — Screen 8 of the Sunset Studio handoff
// (design_handoff_clickerpro_web/README.md).
//
// A `part` of booking_detail_screen.dart so it reuses the SAME controller,
// cancel/advance flows and the full invoice sheet (client invoice, VAT, PDF,
// BN/EN) — only the presentation is web-native:
//   • orange gradient hero with frosted status pill
//   • 3-col info grid: Client (Call / WhatsApp) · Payment (progress bar) ·
//     Delivery checklist (real status milestones)
//   • Assigned Team tiles (gold Chief)
//   • action row + dark "Auto-generate Invoice" panel with COPY / WHATSAPP /
//     MESSENGER chips (share-event-details format) and the full PDF sheet
//   • the deep functional modules (payments, drive link, distributor, task
//     progress, timeline, re-edit) stay embedded below — zero feature loss
//
// Mobile never builds this widget.

part of 'booking_detail_screen.dart';

class _WebBookingDetail extends ConsumerStatefulWidget {
  const _WebBookingDetail({
    required this.screen,
    required this.envelope,
    required this.policy,
    required this.currentUserId,
    required this.lang,
  });

  final BookingDetailScreen screen;
  final BookingDetailEnvelope envelope;
  final RolePolicy policy;
  final String currentUserId;
  final String lang;

  @override
  ConsumerState<_WebBookingDetail> createState() => _WebBookingDetailState();
}

class _WebBookingDetailState extends ConsumerState<_WebBookingDetail> {
  bool _invoiceOpen = false;

  Booking get _booking => widget.envelope.booking;
  BookingDetailEnvelope get _env => widget.envelope;
  RolePolicy get _policy => widget.policy;

  /// The existing invoice action — gives the web panel the exact same
  /// chief/team resolution and the full invoice/PDF sheet.
  _InvoiceAction get _invoiceAction => _InvoiceAction(
        booking: _booking,
        envelope: _env,
        lang: widget.lang,
      );

  String _money(double v) => BookingFormat.money(
        v,
        lang: widget.lang,
        bnNumerals: widget.lang == 'bn',
      );

  (Color, Color, String) _statusLook(BookingStatus s) => switch (s) {
        BookingStatus.pending => (WebTheme.amberDeep, WebTheme.amberTint, 'Pending'),
        BookingStatus.confirmed => (WebTheme.nightText, WebTheme.nightTint, 'Confirmed'),
        BookingStatus.inProgress => (WebTheme.orangeDeep, WebTheme.orangeTint, 'In Progress'),
        BookingStatus.shotComplete => (WebTheme.amberText, WebTheme.amberTint, 'Shot Complete'),
        BookingStatus.delivered => (WebTheme.success, WebTheme.successTint, 'Delivered'),
        BookingStatus.completed => (WebTheme.success, WebTheme.successTint, 'Completed'),
        BookingStatus.cancelled => (WebTheme.danger, WebTheme.dangerTint, 'Cancelled'),
      };

  BookingStatus? _nextStatus() {
    final status = _booking.status;
    final next = _policy.role == UserRole.freelancer
        ? (BookingStatusMachine.canTransition(
                _policy.role, status, BookingStatus.shotComplete)
            ? BookingStatus.shotComplete
            : null)
        : BookingStatusMachine.nextForward(status);
    if (next == null) return null;
    if (!_policy.can(Capability.advanceBookingStatus)) return null;
    if (!BookingStatusMachine.canTransition(_policy.role, status, next)) {
      return null;
    }
    return next;
  }

  bool get _showPayment => shouldShowPayment(
        role: _policy.role,
        hidePaymentFromTeam: _booking.hidePaymentFromTeam,
        canViewPayments: _policy.can(Capability.viewBookingPayments),
      );

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(teamMembersProvider).valueOrNull ??
        const <TeamMember>[];

    final sections = <Widget>[
      const OfflineBanner(),
      _topRow(context),
      _hero(),
      _infoGrid(members),
      _teamSection(members),
      _actionRow(context),
      if (_invoiceOpen) _invoicePanel(context, members),
      if (_isShootDone(_booking.status))
        _DriveLinkSection(
          bookingId: _booking.id,
          driveLink: _booking.driveLink,
        ),
      if (_showPayment)
        PaymentSummaryCard(
          bookingId: _booking.id,
          bookingTotal: _booking.customPrice ?? _env.package?.netPrice,
        ),
      DistributorPanel(
        booking: _booking,
        assignments: _env.assignments,
        currentUserId: widget.currentUserId,
      ),
      TaskProgressSection(
        bookingId: _booking.id,
        assignments: _env.assignments,
        taskProgress: _env.taskProgress,
      ),
      StatusTimeline(entries: _env.statusHistory),
      ReEditSection(booking: _booking, requests: _env.reEditRequests),
      if (_booking.notes != null && _booking.notes!.isNotEmpty)
        WebFormCard(
          label: 'Notes',
          child: Text(
            _booking.notes!,
            style: WebTheme.bodyStyle(size: 13, color: WebTheme.inkSoft),
          ),
        ),
    ];

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => ref
          .read(bookingDetailControllerProvider(widget.screen.bookingId)
              .notifier)
          .refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 64),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: WebStagger(
              children: [
                for (final s in sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: s,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────── TOP ROW
  Widget _topRow(BuildContext context) {
    final next = _nextStatus();
    return Row(
      children: [
        WebBackLink(
          label: '← Back to Bookings',
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        WebTintButton(
          label: 'CALENDAR',
          icon: Icons.event_available_outlined,
          accent: WebTheme.nightText,
          tint: WebTheme.nightTint,
          tintBorder: WebTheme.nightTintBorder,
          mono: true,
          fontSize: 9,
          onTap: () => _addToGoogleCalendar(_booking),
        ),
        const SizedBox(width: 8),
        WebTintButton(
          label: 'REFRESH',
          icon: Icons.sync_rounded,
          accent: WebTheme.inkSoft,
          tint: WebTheme.pageBg,
          tintBorder: WebTheme.hairline,
          mono: true,
          fontSize: 9,
          onTap: () => ref
              .read(bookingDetailControllerProvider(widget.screen.bookingId)
                  .notifier)
              .refresh(),
        ),
        if (_policy.can(Capability.editBooking)) ...[
          const SizedBox(width: 8),
          WebTintButton(
            label: 'EDIT',
            icon: Icons.edit_outlined,
            accent: WebTheme.amberDeep,
            tint: WebTheme.amberTint,
            tintBorder: WebTheme.amberTintBorder,
            mono: true,
            fontSize: 9,
            onTap: () async {
              await Navigator.of(context).pushNamed(
                RouteNames.bookingEdit,
                arguments: widget.screen.bookingId,
              );
              if (!mounted) return;
              await ref
                  .read(bookingDetailControllerProvider(
                          widget.screen.bookingId)
                      .notifier)
                  .refresh();
            },
          ),
        ],
        if (next != null) ...[
          const SizedBox(width: 8),
          WebPillButton(
            label: next == BookingStatus.shotComplete
                ? 'Mark Shoot Complete'
                : 'Move to ${_titleCase(next.name)}',
            icon: next == BookingStatus.shotComplete
                ? Icons.check_circle_outline_rounded
                : Icons.arrow_forward_rounded,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            onTap: () => widget.screen._handleAdvance(context, ref, next),
          ),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────── HERO
  Widget _hero() {
    final b = _booking;
    final (accent, _, statusLabel) = _statusLook(b.status);
    final pkgName = _env.package?.name.trim();
    final label = [
      _titleCase(b.eventType.name).toUpperCase(),
      if (pkgName != null && pkgName.isNotEmpty)
        '${pkgName.toUpperCase()} PACKAGE',
    ].join(' · ');
    final clientLine = _env.client?.name ?? b.clientName ?? b.title;
    final shiftLabel = switch (b.shift) {
      Shift.day => '☀ Day shift',
      Shift.night => '☾ Night shift',
      Shift.both => '◐ Full day',
    };
    final meta = [
      BookingFormat.dateOnly(b.date, lang: widget.lang),
      shiftLabel,
      BookingFormat.clockRange(b.startTime, b.endTime, lang: widget.lang),
      if ((b.venue ?? '').isNotEmpty) '◎ ${b.venue}',
      if (b.outdoor) 'Outdoor',
    ].join(' · ');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: WebTheme.sunset,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        boxShadow: WebTheme.orangeGlow,
      ),
      child: Stack(
        children: [
          // Blurred gold blob, top-right — the handoff hero treatment.
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    WebTheme.amber.withValues(alpha: 0.45),
                    WebTheme.amber.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: WebTheme.label(
                          size: 9.5,
                          color: WebTheme.onOrangeLabel,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Frosted status pill.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(WebTheme.rFull),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: b.status == BookingStatus.cancelled
                                  ? WebTheme.dangerTint
                                  : WebTheme.chromeInk,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            statusLabel.toUpperCase(),
                            style: WebTheme.label(
                              size: 9,
                              color: WebTheme.chromeInk,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  clientLine,
                  style: WebTheme.displayStyle(
                    size: 32,
                    color: WebTheme.chromeInk,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  meta,
                  style: WebTheme.bodyStyle(
                    size: 13,
                    color: WebTheme.onOrangeBody,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────── INFO GRID
  Widget _infoGrid(List<TeamMember> members) {
    final cards = <Widget>[
      _clientCard(),
      if (_showPayment) _paymentCard(),
      _deliveryCard(),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 840) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i != 0) const SizedBox(height: 16),
                cards[i],
              ],
            ],
          );
        }
        final w = (constraints.maxWidth - 16 * (cards.length - 1)) /
            cards.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i != 0) const SizedBox(width: 16),
              SizedBox(width: w, child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _clientCard() {
    final name = _env.client?.name ?? _booking.clientName ?? '—';
    final phone = (_env.client?.phone ?? _booking.clientPhone ?? '').trim();
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return WebFormCard(
      label: 'Client',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: WebTheme.displayStyle(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            phone.isEmpty ? 'No phone on file' : phone,
            style: TextStyle(
              fontFamily: WebTheme.mono,
              fontSize: 12.5,
              color: phone.isEmpty ? WebTheme.inkFaint : WebTheme.inkSoft,
            ),
          ),
          if (_booking.eventType.requiresBrideGroom &&
              ((_booking.brideName ?? '').isNotEmpty ||
                  (_booking.groomName ?? '').isNotEmpty)) ...[
            const SizedBox(height: 8),
            Text(
              [
                if ((_booking.brideName ?? '').isNotEmpty)
                  'Bride: ${_booking.brideName}',
                if ((_booking.groomName ?? '').isNotEmpty)
                  'Groom: ${_booking.groomName}',
              ].join(' · '),
              style: WebTheme.bodyStyle(size: 12, color: WebTheme.inkMuted),
            ),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                WebTintButton(
                  label: '✆ Call',
                  accent: WebTheme.success,
                  tint: WebTheme.successTint,
                  tintBorder: WebTheme.successTintBorder,
                  onTap: () => launchUrl(Uri.parse('tel:$digits')),
                ),
                const SizedBox(width: 8),
                WebTintButton(
                  label: 'WhatsApp',
                  onTap: () => launchUrl(
                    Uri.parse('https://wa.me/${digits.replaceAll('+', '')}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentCard() {
    final total = _booking.customPrice ?? _env.package?.netPrice ?? 0.0;
    final received =
        _env.payments.fold<double>(0, (s, p) => s + p.amount);
    final due = (total - received).clamp(0, double.infinity).toDouble();
    final pct = total <= 0 ? 0.0 : (received / total).clamp(0.0, 1.0);

    Widget row(String label, double v, Color color) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: WebTheme.label(size: 9, color: WebTheme.inkMuted)),
              ),
              Text(
                _money(v),
                style: TextStyle(
                  fontFamily: WebTheme.mono,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );

    return WebFormCard(
      label: 'Payment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('TOTAL', total, WebTheme.ink),
          row('RECEIVED', received, WebTheme.success),
          const Divider(color: WebTheme.innerLine, height: 14),
          row('DUE', due, WebTheme.danger),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(WebTheme.rFull),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: WebTheme.pageBgDeep),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      decoration:
                          const BoxDecoration(gradient: WebTheme.sunsetWide),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(pct * 100).round()}% PAID',
            style: WebTheme.label(size: 9, color: WebTheme.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _deliveryCard() {
    final rank = switch (_booking.status) {
      BookingStatus.pending => 0,
      BookingStatus.confirmed => 1,
      BookingStatus.inProgress => 2,
      BookingStatus.shotComplete => 3,
      BookingStatus.delivered => 4,
      BookingStatus.completed => 5,
      BookingStatus.cancelled => -1,
    };
    final milestones = <(String, int)>[
      ('Confirmed', 1),
      ('Shot complete', 3),
      ('Delivered', 4),
      ('Completed', 5),
    ];
    return WebFormCard(
      label: 'Delivery checklist',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, r) in milestones)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Icon(
                    rank >= r
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 17,
                    color: rank >= r ? WebTheme.success : WebTheme.inkFaint,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: WebTheme.bodyStyle(
                      size: 13,
                      weight: FontWeight.w600,
                      color: rank >= r ? WebTheme.inkMuted : WebTheme.ink,
                    ).copyWith(
                      decoration: rank >= r
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          if (rank == -1)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: WebTheme.dangerTint,
                borderRadius: BorderRadius.circular(WebTheme.rFull),
                border: Border.all(color: WebTheme.dangerTintBorder),
              ),
              child: Text(
                'BOOKING CANCELLED',
                style: WebTheme.label(
                    size: 9, color: WebTheme.danger, weight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────── TEAM
  Widget _teamSection(List<TeamMember> members) {
    final chiefId = _booking.chiefPhotographerUserId;
    TeamMember? memberFor(String userId) =>
        members.where((m) => m.userId == userId).firstOrNull;

    Widget tile({
      required String name,
      required String roleLabel,
      required String phone,
      required Color accent,
      required Color tint,
      required Color tintBorder,
      bool chief = false,
      String? payout,
    }) {
      return Container(
        width: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(WebTheme.rTile),
          border: Border.all(color: tintBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: chief ? WebTheme.chrome : WebTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: chief ? WebTheme.amber : tintBorder,
                  width: chief ? 2 : 1,
                ),
              ),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: WebTheme.displayStyle(
                  size: 14,
                  color: chief ? WebTheme.amber : accent,
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
                    chief ? '$name ★' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.bodyStyle(
                        size: 13, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      roleLabel.toUpperCase(),
                      ?payout,
                      if (phone.isNotEmpty) phone,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.label(size: 8.5, color: WebTheme.inkMuted),
                  ),
                ],
              ),
            ),
            if (phone.isNotEmpty)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(
                      'tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}')),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WebTheme.successTint,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: WebTheme.successTintBorder),
                    ),
                    child: const Icon(Icons.call_outlined,
                        size: 14, color: WebTheme.success),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final tiles = <Widget>[];
    // Free-typed chief (not an assignment row) still gets the gold tile.
    if (chiefId != null &&
        !_env.assignments.any((a) => a.userId == chiefId)) {
      final m = memberFor(chiefId);
      tiles.add(tile(
        name: m?.fullName ?? chiefId,
        roleLabel: 'Chief Photographer',
        phone: (m?.phone ?? '').trim(),
        accent: WebTheme.amberDeep,
        tint: WebTheme.amberTint,
        tintBorder: WebTheme.amberTintBorder,
        chief: true,
      ));
    }
    for (final a in _env.assignments) {
      final m = memberFor(a.userId);
      final isChief = a.userId == chiefId;
      final isCine = a.role == AssignmentRole.cinematographer;
      tiles.add(tile(
        name: m?.fullName ?? a.userId,
        roleLabel: _titleCase(a.role.name),
        phone: (m?.phone ?? '').trim(),
        accent: isChief
            ? WebTheme.amberDeep
            : (isCine ? WebTheme.nightText : WebTheme.orangeDeep),
        tint: isChief
            ? WebTheme.amberTint
            : (isCine ? WebTheme.nightTint : WebTheme.orangeTint),
        tintBorder: isChief
            ? WebTheme.amberTintBorder
            : (isCine ? WebTheme.nightTintBorder : WebTheme.orangeTintBorder),
        chief: isChief,
        payout: _showPayment && a.payout > 0 ? _money(a.payout) : null,
      ));
    }

    return WebFormCard(
      label: 'Assigned Team',
      child: tiles.isEmpty
          ? Text(
              'No team assigned yet.',
              style: WebTheme.bodyStyle(size: 12.5, color: WebTheme.inkMuted),
            )
          : Wrap(spacing: 12, runSpacing: 12, children: tiles),
    );
  }

  // ───────────────────────────────────────────────── ACTIONS + INVOICE
  Widget _actionRow(BuildContext context) {
    final canCancel = _policy.can(Capability.cancelBooking) &&
        _booking.status != BookingStatus.cancelled;
    return Row(
      children: [
        WebPillButton(
          label: _invoiceOpen
              ? 'Hide Invoice Panel'
              : '⚡ Auto-generate Invoice',
          onTap: () => setState(() => _invoiceOpen = !_invoiceOpen),
        ),
        const SizedBox(width: 10),
        WebTintButton(
          label: 'Client Invoice · PDF',
          onTap: () =>
              _invoiceAction._showInvoiceSheet(context, ref, forClient: true),
        ),
        const SizedBox(width: 10),
        WebTintButton(
          label: 'Share Event Details',
          accent: WebTheme.nightText,
          tint: WebTheme.nightTint,
          tintBorder: WebTheme.nightTintBorder,
          onTap: () =>
              _invoiceAction._showInvoiceSheet(context, ref, forClient: false),
        ),
        const Spacer(),
        if (canCancel)
          WebTintButton(
            label: 'Cancel Booking',
            accent: WebTheme.danger,
            tint: WebTheme.dangerTint,
            tintBorder: WebTheme.dangerTintBorder,
            onTap: () => widget.screen._handleCancel(context, ref),
          ),
      ],
    );
  }

  Widget _invoicePanel(BuildContext context, List<TeamMember> members) {
    final b = _booking;
    final chiefName = _invoiceAction._resolveChiefName(members);
    final chiefPhone = _invoiceAction._resolveChiefPhone(members);
    final teamNames = _env.assignments
        .map((a) =>
            members.where((m) => m.userId == a.userId).firstOrNull?.fullName ??
            _titleCase(a.role.name))
        .where((s) => s.trim().isNotEmpty)
        .join(', ');

    final cfg = ref.read(currencyControllerProvider).valueOrNull;
    final subtotal = b.customPrice ?? _env.package?.netPrice ?? 0.0;
    final vat = cfg?.vatOn(subtotal) ?? 0.0;
    final total = subtotal + vat;
    final advance = _env.payments.fold<double>(0, (s, p) => s + p.amount);
    final due = total - advance;

    final shiftLabel = switch (b.shift) {
      Shift.day => 'Day',
      Shift.night => 'Night',
      Shift.both => 'Full Day',
    };

    final rows = <(String, String, bool)>[
      ('DATE', BookingFormat.dateOnly(b.date, lang: widget.lang), false),
      (
        'TIME',
        '$shiftLabel · ${BookingFormat.clockRange(b.startTime, b.endTime, lang: widget.lang)}',
        false
      ),
      ('EVENT', _titleCase(b.eventType.name), false),
      ('CLIENT', _env.client?.name ?? b.clientName ?? '—', false),
      ('PHONE', _env.client?.phone ?? b.clientPhone ?? '—', false),
      ('VENUE', b.venue ?? '—', false),
      if (chiefName != '—') ('CHIEF', chiefName, false),
      if (teamNames.isNotEmpty) ('TEAM', teamNames, false),
      if (chiefPhone.isNotEmpty) ('TEAM NO', chiefPhone, false),
      if (_showPayment) ...[
        ('TOTAL', _money(total), false),
        ('ADVANCE', _money(advance), false),
        ('DUE', _money(due), true),
      ],
    ];

    final me = ref.read(currentUserProvider).valueOrNull;
    final studioName = (me?.companyName?.trim().isNotEmpty ?? false)
        ? me!.companyName!.trim()
        : (me?.name ?? 'GRAPHY7');
    final mePhone = (me?.phone ?? '').trim();
    final copyText = [
      for (final (k, v, _) in rows) '$k: $v',
      '',
      'Company name: $studioName',
      if (mePhone.isNotEmpty) 'Contact no: $mePhone',
    ].join('\n');

    return WebEntrance(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: WebTheme.chrome,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          boxShadow: WebTheme.darkCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AUTO-GENERATED INVOICE',
                    style: WebTheme.label(
                      size: 9.5,
                      color: WebTheme.amber,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'BN/EN · PDF VIA CLIENT INVOICE',
                  style:
                      WebTheme.label(size: 8.5, color: WebTheme.chromeInkFaint),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final (k, v, danger) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        k,
                        style: WebTheme.label(
                            size: 9, color: WebTheme.chromeInkFaint),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        v,
                        style: TextStyle(
                          fontFamily: WebTheme.mono,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: danger
                              ? const Color(0xFFFF9B7A)
                              : WebTheme.chromeInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                WebTintButton(
                  label: 'COPY',
                  mono: true,
                  fontSize: 9,
                  accent: WebTheme.amber,
                  tint: const Color(0x26F5B02E),
                  tintBorder: const Color(0x59F5B02E),
                  textColor: WebTheme.amber,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: copyText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice copied ✓')),
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
                  onTap: () => launchUrl(
                    Uri.parse(
                        'https://wa.me/?text=${Uri.encodeComponent(copyText)}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const SizedBox(width: 8),
                WebTintButton(
                  label: 'MESSENGER / SHARE',
                  mono: true,
                  fontSize: 9,
                  accent: WebTheme.night,
                  tint: const Color(0x268B5CF6),
                  tintBorder: const Color(0x598B5CF6),
                  textColor: const Color(0xFFC9B2F9),
                  onTap: () => SharePlus.instance.share(
                    ShareParams(text: copyText, subject: 'Event details'),
                  ),
                ),
                const Spacer(),
                WebTintButton(
                  label: 'PDF ↓',
                  mono: true,
                  fontSize: 9,
                  accent: WebTheme.chromeInk,
                  tint: const Color(0x14FFF6EE),
                  tintBorder: WebTheme.chromeLine,
                  textColor: WebTheme.chromeInkMuted,
                  onTap: () => _invoiceAction._showInvoiceSheet(
                    context,
                    ref,
                    forClient: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

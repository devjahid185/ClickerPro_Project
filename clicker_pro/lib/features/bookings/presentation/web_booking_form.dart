// lib/features/bookings/presentation/web_booking_form.dart
//
// WEB-ONLY New/Edit Booking form — Screen 7 of the Sunset Studio handoff
// (design_handoff_clickerpro_web/README.md, "Form v6 / FL-12").
//
// A `part` of booking_edit_screen.dart so it drives the SAME state, text
// controllers, validation and save pipeline as the mobile form — zero logic
// duplication, only the presentation differs:
//   • 860px column of white section cards, fade-up staggered
//   • pinned action bar: ← BACK · status · orange "Save Booking" pill
//   • shift pills (DAY = orange fill, NIGHT = purple fill)
//   • package selector tiles that auto-fill the payment total
//   • removable team chips + gold Chief toggle
//   • payment tiles (Total auto / Advance / Due) + bKash/Bank/Cash chips
//   • live conflict tile for the freelancer 1-per-shift rule
//
// Mobile never builds this widget, so the phone form is untouched.

part of 'booking_edit_screen.dart';

class _WebBookingForm extends ConsumerWidget {
  const _WebBookingForm({required this.state, required this.draft});

  final _BookingEditScreenState state;
  final BookingDraft draft;

  BookingEditController get _controller => state.ref.read(
    bookingEditControllerProvider(state.widget.bookingId).notifier,
  );

  bool get _isCreate => state.widget.bookingId == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(bookingsPolicyProvider);
    final isBothRole = policy.role == UserRole.both;
    final isFreelancer = policy.role == UserRole.freelancer;
    final showFreelancer =
        isFreelancer || (isBothRole && state._showFreelancerForm);

    final sections = <Widget>[
      if (isBothRole) _bookedByCard(),
      if (showFreelancer) ...[
        _companyCard(),
        _scheduleCard(context, ref, policy, freelancer: true),
        _eventTypeCard(),
        // Notes are hidden from booking forms for now.
      ] else ...[
        _clientCard(),
        _scheduleCard(context, ref, policy, freelancer: false),
        if (_isCreate) _multiDayCard(ref),
        _packageCard(ref),
        _teamCard(context, ref),
        _eventTypeCard(),
        if (draft.eventType.requiresBrideGroom) _coupleCard(),
        _paymentCard(ref, policy),
        _notesCard(freelancer: false),
      ],
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: _actionBar(),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
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
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────── ACTION BAR
  Widget _actionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rTile),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2B1D12),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          WebBackLink(label: '← Back', onTap: () => state._webBack()),
          const Spacer(),
          Text(
            state._dirty
                ? '● UNSAVED CHANGES'
                : (_isCreate ? 'NEW BOOKING' : 'EDIT BOOKING'),
            style: WebTheme.label(
              size: 9,
              color: state._dirty ? WebTheme.amberDeep : WebTheme.success,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 18),
          WebPillButton(
            label: state._saving
                ? 'Saving...'
                : (_isCreate ? 'Save Booking' : 'Save Changes'),
            enabled: !state._saving,
            onTap: () => state._onSave(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────── BOOKED BY (Both role)
  Widget _bookedByCard() {
    return WebFormCard(
      label: 'Booked by',
      child: Row(
        children: [
          Expanded(
            child: _segmentPill(
              label: 'FREELANCER',
              icon: Icons.camera_alt_outlined,
              selected: state._showFreelancerForm,
              onTap: () {
                state._webSet(() => state._showFreelancerForm = true);
                _controller.setFreelancerMode(true);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _segmentPill(
              label: 'STUDIO / OWNER',
              icon: Icons.business_center_outlined,
              selected: !state._showFreelancerForm,
              onTap: () {
                state._webSet(() => state._showFreelancerForm = false);
                _controller.setFreelancerMode(false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentPill({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: WebTheme.fast,
          curve: WebTheme.ease,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? WebTheme.orange : WebTheme.pageBg,
            borderRadius: BorderRadius.circular(WebTheme.rFull),
            border: Border.all(
              color: selected ? WebTheme.orange : WebTheme.hairline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? WebTheme.chromeInk : WebTheme.inkMuted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: WebTheme.label(
                  size: 10,
                  color: selected ? WebTheme.chromeInk : WebTheme.inkSoft,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────── CLIENT / COMPANY
  Widget _clientCard() {
    return WebFormCard(
      label: 'Client',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: WebTextInput(
              label: 'Client Name',
              required: true,
              controller: state._clientNameCtrl,
              hint: 'e.g. Rahat & Tasnim',
              errorText: state._validation.errorFor(BookingField.client),
              onChanged: (v) {
                state._markDirty();
                _controller.setClientName(v.trim().isEmpty ? null : v);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: WebTextInput(
              label: 'Phone Number',
              controller: state._clientPhoneCtrl,
              hint: '+880 1XXXXXXXXX',
              keyboardType: TextInputType.phone,
              errorText: state._validation.errorFor(BookingField.clientPhone),
              onChanged: (v) {
                state._markDirty();
                _controller.setClientPhone(v.trim().isEmpty ? null : v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyCard() {
    return WebFormCard(
      label: 'Booked by',
      child: WebTextInput(
        label: 'Company Name',
        controller: state._companyNameCtrl,
        hint: 'Studio or brand name',
        onChanged: (v) {
          state._markDirty();
          _controller.setClientName(v.trim().isEmpty ? null : v);
        },
      ),
    );
  }

  // ───────────────────────────────────────────────── SCHEDULE
  Widget _scheduleCard(
    BuildContext context,
    WidgetRef ref,
    RolePolicy policy, {
    required bool freelancer,
  }) {
    return WebFormCard(
      label: 'Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _shiftPills(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: WebPickerField(
                  label: 'Date',
                  required: true,
                  valueText: draft.date == null
                      ? null
                      : DateFormat('EEE, d MMMM yyyy').format(draft.date!),
                  placeholder: 'Pick a date',
                  errorText: state._validation.errorFor(BookingField.date),
                  onTap: () => state._pickDate(draft, _controller),
                ),
              ),
              if (!freelancer) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: WebTextInput(
                    label: 'Venue',
                    controller: state._venueCtrl,
                    hint: 'Garden Hall, Banani',
                    onChanged: (v) {
                      state._markDirty();
                      _controller.setVenue(v.isEmpty ? null : v);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          WebTextInput(
            label: 'Location Map (optional)',
            controller: state._mapLinkCtrl,
            hint: 'Paste a Google Maps link or place name',
            keyboardType: TextInputType.url,
            suffix: IconButton(
              tooltip: 'Open in maps',
              icon: const Icon(
                Icons.location_on_outlined,
                color: WebTheme.success,
                size: 18,
              ),
              onPressed: () => state._openMapLink(state._mapLinkCtrl.text),
            ),
            onChanged: (v) {
              state._markDirty();
              _controller.setMapLink(v.isEmpty ? null : v);
            },
          ),
          const SizedBox(height: 16),
          WebToggleRow(
            label: 'Outdoor Event',
            subtitle: 'Affects gear / weather planning.',
            value: draft.outdoor,
            onChanged: (v) {
              state._markDirty();
              _controller.setOutdoor(v);
            },
          ),
          if (draft.outdoor) ...[
            const SizedBox(height: 14),
            WebEntrance(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: WebTextInput(
                      label: 'Location',
                      controller: state._locationCtrl,
                      hint: 'Beach, park, etc.',
                      onChanged: (_) => state._markDirty(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: WebTextInput(
                      label: 'Reporting Time',
                      controller: state._reportingTimeCtrl,
                      hint: 'e.g. 07:00',
                      onChanged: (_) => state._markDirty(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          _conflictTile(ref, policy),
        ],
      ),
    );
  }

  Widget _shiftPills() {
    Widget pill(Shift shift) {
      final selected = draft.shift == shift;
      final (label, icon, fill) = switch (shift) {
        Shift.day => ('DAY · 12–5', Icons.wb_sunny_outlined, WebTheme.orange),
        Shift.night => (
          'NIGHT · 6–11',
          Icons.nightlight_outlined,
          WebTheme.night,
        ),
        Shift.both => (
          'FULL DAY',
          Icons.brightness_6_outlined,
          WebTheme.amberDeep,
        ),
      };
      return Expanded(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              state._markDirty();
              _controller.setShift(shift);
            },
            child: AnimatedContainer(
              duration: WebTheme.base,
              curve: WebTheme.ease,
              margin: EdgeInsets.only(right: shift != Shift.both ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? fill : WebTheme.pageBg,
                borderRadius: BorderRadius.circular(WebTheme.rFull),
                border: Border.all(color: selected ? fill : WebTheme.hairline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: selected ? WebTheme.chromeInk : WebTheme.inkMuted,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: WebTheme.label(
                      size: 10,
                      color: selected ? WebTheme.chromeInk : WebTheme.inkSoft,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [for (final s in Shift.values) pill(s)]);
  }

  /// Live scheduling-clash tile. Freelancer mode = the strict 1-per-shift
  /// rule (blocks save unless Distribution mode is on); owners may stack,
  /// so they only get an informational note.
  Widget _conflictTile(WidgetRef ref, RolePolicy policy) {
    if (draft.date == null) return const SizedBox.shrink();
    final bookings =
        ref.watch(bookingListAllProvider(const BookingFilter())).valueOrNull ??
        const <Booking>[];
    final day = DateTime(draft.date!.year, draft.date!.month, draft.date!.day);
    bool shiftsClash(Shift a, Shift b) =>
        a == Shift.both || b == Shift.both || a == b;
    final clash = bookings.where((b) {
      if (b.id == draft.localId) return false;
      if (b.status == BookingStatus.cancelled) return false;
      final bDay = DateTime(b.date.year, b.date.month, b.date.day);
      return bDay == day && shiftsClash(b.shift, draft.shift);
    }).firstOrNull;
    if (clash == null) return const SizedBox.shrink();

    final freelancerRule =
        policy.role == UserRole.freelancer || draft.freelancerMode;
    final text = freelancerRule
        ? 'Conflict: a booking already exists on this date/shift — '
              '"${clash.title}". One event per shift; turn on Settings → '
              'Distribution to allow more, otherwise this will block save.'
        : 'Heads up: "${clash.title}" is already booked on this date/shift. '
              'Owners can stack events — saving will add another booking to '
              'the same slot.';

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: freelancerRule ? WebTheme.dangerTint : WebTheme.amberTint,
          borderRadius: BorderRadius.circular(WebTheme.rRow),
          border: Border.all(
            color: freelancerRule
                ? WebTheme.dangerTintBorder
                : WebTheme.amberTintBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: freelancerRule ? WebTheme.danger : WebTheme.amberDeep,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: WebTheme.bodyStyle(
                  size: 12,
                  color: freelancerRule ? WebTheme.danger : WebTheme.amberText,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────── MULTI-DAY
  Widget _multiDayCard(WidgetRef ref) {
    final packages = ref.watch(packagesProvider).valueOrNull ?? const [];
    final primaryPkg = draft.packageId == null
        ? null
        : packages.where((p) => p.id == draft.packageId).firstOrNull;
    final primary = draft.customPrice ?? primaryPkg?.netPrice ?? 0;
    final extrasTotal = state._extraEvents.fold<double>(
      0,
      (s, e) => s + e.price,
    );
    final grand = primary + extrasTotal;

    return WebFormCard(
      label: 'Multi-day booking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebToggleRow(
            label: 'Book more days for this client',
            subtitle:
                'Each extra day saves as its own booking with its own package.',
            value: state._multiEventOn,
            onChanged: (v) {
              state._markDirty();
              state._webSet(() {
                state._multiEventOn = v;
                if (!v) state._extraEvents.clear();
              });
            },
          ),
          if (state._multiEventOn) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < state._extraEvents.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: WebTheme.pageBg,
                  borderRadius: BorderRadius.circular(WebTheme.rRow),
                  border: Border.all(color: WebTheme.hairline),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 16,
                      color: WebTheme.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${DateFormat('d MMM yyyy').format(state._extraEvents[i].date)}'
                        ' · ${state._extraEvents[i].label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WebTheme.bodyStyle(
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      ActiveCurrency.value.wrap(
                        state._extraEvents[i].price.toStringAsFixed(0),
                      ),
                      style: WebTheme.bodyStyle(
                        size: 13,
                        color: WebTheme.orangeDeep,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          state._markDirty();
                          state._webSet(() => state._extraEvents.removeAt(i));
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: WebTheme.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: WebTintButton(
                label: '+ Add day & package',
                onTap: () => state._addExtraEvent(draft),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'TOTAL · ${1 + state._extraEvents.length} '
                    '${state._extraEvents.isEmpty ? 'DAY' : 'DAYS'}',
                    style: WebTheme.label(size: 9, color: WebTheme.inkMuted),
                  ),
                ),
                Text(
                  ActiveCurrency.value.wrap(grand.toStringAsFixed(0)),
                  style: WebTheme.displayStyle(
                    size: 17,
                    color: WebTheme.orangeDeep,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────── PACKAGE
  Widget _packageCard(WidgetRef ref) {
    final packagesAsync = ref.watch(packagesProvider);
    final packages = packagesAsync.valueOrNull ?? const [];
    const accents = [
      WebTheme.orange,
      WebTheme.amber,
      WebTheme.night,
      WebTheme.tan,
    ];
    final customSelected = draft.packageId == null && draft.customPrice != null;

    Widget tile({
      required String name,
      required String price,
      required Color accent,
      required bool selected,
      required VoidCallback onTap,
      String? sub,
    }) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: WebTheme.fast,
            curve: WebTheme.ease,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: selected ? WebTheme.orangeTint : WebTheme.pageBg,
              borderRadius: BorderRadius.circular(WebTheme.rRow),
              border: Border.all(
                color: selected ? WebTheme.orangeTintBorder : WebTheme.hairline,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(WebTheme.rFull),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WebTheme.displayStyle(
                          size: 13.5,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub ?? price,
                        style: WebTheme.label(
                          size: 10,
                          color: selected
                              ? WebTheme.orangeDeep
                              : WebTheme.inkMuted,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: WebTheme.orange,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return WebFormCard(
      label: 'Package',
      trailing: Text(
        'AUTO-FILLS PAYMENT TOTAL',
        style: WebTheme.label(size: 8.5, color: WebTheme.inkFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (packagesAsync.isLoading && packages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Loading packages…',
                style: WebTheme.bodyStyle(size: 12, color: WebTheme.inkMuted),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth >= 560;
              final w = twoCol
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < packages.length; i++)
                    SizedBox(
                      width: w,
                      child: tile(
                        name: packages[i].name,
                        price: ActiveCurrency.value.wrap(
                          packages[i].netPrice.toStringAsFixed(0),
                        ),
                        accent: accents[i % accents.length],
                        selected: draft.packageId == packages[i].id,
                        onTap: () {
                          state._markDirty();
                          state._applyPackage(packages[i], draft, _controller);
                        },
                      ),
                    ),
                  SizedBox(
                    width: w,
                    child: tile(
                      name: 'Custom',
                      price: 'MANUAL PRICE',
                      sub: 'MANUAL PRICE',
                      accent: WebTheme.tan,
                      selected: customSelected,
                      onTap: () {
                        state._markDirty();
                        _controller.setCustomPrice(
                          double.tryParse(state._customPriceCtrl.text) ?? 0,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          if (customSelected) ...[
            const SizedBox(height: 14),
            WebEntrance(
              child: WebTextInput(
                label: 'Custom Price',
                controller: state._customPriceCtrl,
                hint: 'e.g. 30000',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: state._validation.errorFor(BookingField.customPrice),
                onChanged: (v) {
                  state._markDirty();
                  _controller.setCustomPrice(double.tryParse(v));
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────── TEAM
  Widget _teamCard(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamMembersProvider).valueOrNull ?? const [];
    String nameFor(String userId) {
      final m = members.where((m) => m.userId == userId).firstOrNull;
      final name = m?.fullName ?? '';
      return name.isEmpty ? userId : name;
    }

    Widget memberColumn({
      required String label,
      required IconData icon,
      required AssignmentRole role,
      required Color accent,
      required Color tint,
      required Color tintBorder,
    }) {
      final assigned = draft.assignments.where((a) => a.role == role).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: WebTheme.label(size: 9, color: WebTheme.inkMuted),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(WebTheme.rFull),
                  border: Border.all(color: tintBorder),
                ),
                child: Text(
                  '${assigned.length}',
                  style: WebTheme.label(
                    size: 9,
                    color: accent,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in assigned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(WebTheme.rFull),
                    border: Border.all(color: tintBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nameFor(a.userId),
                        style: WebTheme.bodyStyle(
                          size: 12,
                          color: accent,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 7),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            state._markDirty();
                            _controller.removeAssignment(a.id);
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              WebSelectChip(
                label: '+ Add',
                selected: false,
                onTap: () => state._addTeamMember(context, _controller, role),
              ),
            ],
          ),
        ],
      );
    }

    return WebFormCard(
      label: 'Team',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebToggleRow(
            label: '★ Chief Photographer',
            subtitle: 'Designate a lead photographer for this event.',
            value: state._chiefEnabled,
            activeColor: WebTheme.amber,
            background: state._chiefEnabled
                ? WebTheme.amberTint
                : WebTheme.pageBg,
            border: state._chiefEnabled
                ? WebTheme.amberTintBorder
                : WebTheme.hairline,
            onChanged: (v) {
              state._markDirty();
              state._webSet(() => state._chiefEnabled = v);
              if (!v) {
                _controller.setChiefPhotographerUserId(null);
                state._chiefNameCtrl.clear();
              }
            },
          ),
          if (state._chiefEnabled) ...[
            const SizedBox(height: 14),
            WebEntrance(
              child: WebTextInput(
                label: 'Chief Photographer Name',
                controller: state._chiefNameCtrl,
                hint: 'Type a name or pick from team',
                suffix: IconButton(
                  tooltip: 'Pick from team',
                  icon: const Icon(
                    Icons.group_add_outlined,
                    color: WebTheme.amberDeep,
                    size: 18,
                  ),
                  onPressed: () => state._pickChiefFromTeam(_controller),
                ),
                onChanged: (v) {
                  state._markDirty();
                  _controller.setChiefPhotographerUserId(
                    v.trim().isEmpty ? null : v.trim(),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final photographers = memberColumn(
                label: 'Photographers',
                icon: Icons.camera_alt_outlined,
                role: AssignmentRole.photographer,
                accent: WebTheme.orangeDeep,
                tint: WebTheme.orangeTint,
                tintBorder: WebTheme.orangeTintBorder,
              );
              final cinematographers = memberColumn(
                label: 'Cinematographers',
                icon: Icons.videocam_outlined,
                role: AssignmentRole.cinematographer,
                accent: WebTheme.nightText,
                tint: WebTheme.nightTint,
                tintBorder: WebTheme.nightTintBorder,
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    photographers,
                    const SizedBox(height: 18),
                    cinematographers,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: photographers),
                  const SizedBox(width: 24),
                  Expanded(child: cinematographers),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────── EVENT TYPE
  Widget _eventTypeCard() {
    return WebFormCard(
      label: 'Event Type',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final type in EventType.values)
            WebSelectChip(
              label: _eventTypeChipLabel(type),
              selected: draft.eventType == type,
              onTap: () {
                state._markDirty();
                _controller.setEventType(type);
              },
            ),
        ],
      ),
    );
  }

  Widget _coupleCard() {
    return WebFormCard(
      label: 'Couple',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: WebTextInput(
              label: 'Bride',
              controller: state._brideCtrl,
              hint: 'Optional',
              onChanged: (v) {
                state._markDirty();
                _controller.setBrideName(v.isEmpty ? null : v);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: WebTextInput(
              label: 'Groom',
              controller: state._groomCtrl,
              hint: 'Optional',
              onChanged: (v) {
                state._markDirty();
                _controller.setGroomName(v.isEmpty ? null : v);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────── PAYMENT
  Widget _paymentCard(WidgetRef ref, RolePolicy policy) {
    final packages = ref.watch(packagesProvider).valueOrNull ?? const [];
    final pkgNet = draft.packageId == null
        ? null
        : packages.where((p) => p.id == draft.packageId).firstOrNull?.netPrice;
    final primaryTotal = draft.customPrice ?? pkgNet;
    final extrasTotal = state._multiEventOn
        ? state._extraEvents.fold<double>(0, (s, e) => s + e.price)
        : 0.0;
    final total = primaryTotal == null ? null : primaryTotal + extrasTotal;
    if (total != null) {
      final txt = total.toStringAsFixed(0);
      if (state._totalCtrl.text != txt) state._totalCtrl.text = txt;
    }
    final canHide = policy.can(Capability.toggleHidePayment);

    Widget tile({
      required String label,
      required Color bg,
      required Color border,
      required Widget child,
    }) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(WebTheme.rRow),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: WebTheme.label(size: 8.5)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      );
    }

    TextStyle amountStyle(Color color) => TextStyle(
      fontFamily: WebTheme.mono,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: color,
    );

    Widget amountField(
      TextEditingController ctrl,
      Color color, {
      required ValueChanged<String> onChanged,
    }) {
      return TextField(
        controller: ctrl,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: amountStyle(color),
        cursorColor: WebTheme.orange,
        decoration: InputDecoration(
          isDense: true,
          isCollapsed: true,
          border: InputBorder.none,
          hintText: '0',
          hintStyle: amountStyle(WebTheme.inkFaint),
        ),
      );
    }

    return WebFormCard(
      label: 'Payment',
      trailing: canHide
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  state._markDirty();
                  _controller.setHidePaymentFromTeam(
                    !draft.hidePaymentFromTeam,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      draft.hidePaymentFromTeam
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 14,
                      color: draft.hidePaymentFromTeam
                          ? WebTheme.amberDeep
                          : WebTheme.inkMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      draft.hidePaymentFromTeam
                          ? 'HIDDEN FROM TEAM'
                          : 'HIDE FROM TEAM',
                      style: WebTheme.label(
                        size: 9,
                        color: draft.hidePaymentFromTeam
                            ? WebTheme.amberDeep
                            : WebTheme.inkMuted,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder(
            valueListenable: state._advanceCtrl,
            builder: (context, advanceValue, _) {
              return ValueListenableBuilder(
                valueListenable: state._totalCtrl,
                builder: (context, totalValue, _) {
                  final totalNum = double.tryParse(totalValue.text) ?? 0;
                  final advanceNum = double.tryParse(advanceValue.text) ?? 0;
                  final due = totalNum - advanceNum;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: tile(
                          label: 'TOTAL (AUTO)',
                          bg: WebTheme.orangeTint,
                          border: WebTheme.orangeTintBorder,
                          child: amountField(
                            state._totalCtrl,
                            WebTheme.orangeDeep,
                            onChanged: (v) {
                              state._markDirty();
                              final typedTotal = double.tryParse(v);
                              _controller.setCustomPrice(
                                typedTotal == null
                                    ? null
                                    : math.max(typedTotal - extrasTotal, 0),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: tile(
                          label: 'ADVANCE',
                          bg: WebTheme.pageBg,
                          border: WebTheme.hairline,
                          child: amountField(
                            state._advanceCtrl,
                            WebTheme.ink,
                            onChanged: (_) => state._markDirty(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: tile(
                          label: 'DUE (AUTO)',
                          bg: WebTheme.dangerTint,
                          border: WebTheme.dangerTintBorder,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              ActiveCurrency.value.wrap(
                                (due < 0 ? 0 : due).toStringAsFixed(0),
                              ),
                              style: amountStyle(WebTheme.danger),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          // Inline error under the payment tiles — names the missing
          // Package/Price or Advance so web users see WHERE the error is
          // (Heaven 2026-07-15: "কোথায় এরর সেটা দেখাবে").
          Builder(
            builder: (_) {
              final priceErr = state._validation.errorFor(
                BookingField.customPrice,
              );
              final advErr = state._validation.errorFor(BookingField.advance);
              final msg = priceErr ?? advErr;
              if (msg == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  msg,
                  style: WebTheme.bodyStyle(size: 12, color: WebTheme.danger),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'ADVANCE METHOD',
                style: WebTheme.label(size: 9, color: WebTheme.inkMuted),
              ),
              const SizedBox(width: 14),
              for (final (label, value) in const [
                ('bKash', 'bkash'),
                ('Bank', 'bank'),
                ('Cash', 'cash'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: WebSelectChip(
                    label: label,
                    selected: state._advanceMethod == value,
                    onTap: () =>
                        state._webSet(() => state._advanceMethod = value),
                  ),
                ),
            ],
          ),
          if (canHide) ...[
            const SizedBox(height: 16),
            WebToggleRow(
              label: 'Show payment in shared details',
              subtitle:
                  'Off by default. When on, Total / Advance / Due appear on '
                  'shared event details.',
              value: draft.showPaymentInShare,
              onChanged: (v) {
                state._markDirty();
                _controller.setShowPaymentInShare(v);
              },
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Invoice is generated after save — Saved ✓ → Invoice.',
            style: WebTheme.bodyStyle(size: 11.5, color: WebTheme.inkMuted),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────── NOTES
  Widget _notesCard({required bool freelancer}) {
    if (freelancer) return const SizedBox.shrink();
    return WebFormCard(
      label: 'Client Requirements',
      child: WebTextInput(
        label: 'Client Requirements (optional)',
        controller: state._requirementsCtrl,
        hint: 'Print, album, pendrive, delivery system...',
        maxLines: 3,
        onChanged: (v) {
          state._markDirty();
          _controller.setRequirementsNote(v.isEmpty ? null : v);
        },
      ),
    );
  }
}

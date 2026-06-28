// lib/features/bookings/presentation/booking_edit_screen.dart
//
// Combined create / edit form for a Booking. The screen is keyed by an
// optional booking local id — `null` opens a fresh draft, a non-null id
// loads the existing booking from Drift.
//
// State + validation live in `BookingEditController`. The screen owns
// only the per-field `TextEditingController`s and the form-key, and
// proxies every other change through the controller. On submit, it
// runs `controller.save()` which performs validation + persistence;
// validation failures bubble up as `BookingValidationException` and
// are mapped to inline error text.
//
// Visibility gating:
//   • Whole screen           — `editBooking` (existing) / `createBooking` (new)
//   • Hide-payment toggle    — `Capability.toggleHidePayment` (Owner / Both)
//
// Pickers (date / time / client / package) open as bottom sheets so
// they share a single transition contract with the rest of the app.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Booking Edit Screen". Validates Requirements 2.1–2.13, 11.6.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/notifications/event_reminder_service.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/widgets/celebration.dart';
import '../../../theme/app_colors.dart';
import '../../auth/domain/user_role.dart';
import '../../calendar_sync/data/calendar_sync_service.dart';
import '../../profile/application/profile_controllers.dart';
import '../../../core/providers.dart';
import '../application/booking_conflict.dart';
import '../application/booking_edit_controller.dart';
import '../application/booking_providers.dart';
import '../domain/assignment_role.dart';
import '../domain/booking.dart';
import '../domain/booking_filter.dart';
import '../domain/event_type.dart';
import '../domain/package.dart';
import '../domain/shift.dart';
import 'widgets/assignments_editor.dart';
import 'widgets/lens_form_fields.dart';
import 'widgets/team_member_picker_sheet.dart';

class BookingEditScreen extends ConsumerStatefulWidget {
  const BookingEditScreen({super.key, this.bookingId});

  /// `null` for create mode; non-null for edit mode.
  final String? bookingId;

  @override
  ConsumerState<BookingEditScreen> createState() => _BookingEditScreenState();
}

class _BookingEditScreenState extends ConsumerState<BookingEditScreen>
    with TickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _brideCtrl = TextEditingController();
  final _groomCtrl = TextEditingController();
  final _coverageCtrl = TextEditingController();
  final _extraRateCtrl = TextEditingController();
  final _customPriceCtrl = TextEditingController();
  final _driveLinkCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _reportingTimeCtrl = TextEditingController();
  final _chiefNameCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();

  BookingValidation _validation = const BookingValidation({});
  bool _seeded = false;
  bool _dirty = false;

  /// Whether the Chief Photographer section is toggled on. Kept as
  /// local UI state — deriving it from `chiefPhotographerUserId` made
  /// the toggle a no-op (turning it ON set nothing, so the name field
  /// never appeared and a chief could never be added).
  bool _chiefEnabled = false;

  /// When `true`, the Freelancer short-form (FL-12) is shown instead
  /// of the full Owner form. Only relevant when role is `UserRole.both`.
  bool _showFreelancerForm = false;

  /// Whether the hide-payment eye is toggled on.
  bool _hidePaymentVisible = true;

  /// Collapsible section states.
  bool _eventTypesExpanded = false;
  bool _packageSectionExpanded = false;

  /// Flash animation for package auto-fill.
  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;

  /// Shake animation controller for validation errors.
  late AnimationController _shakeCtrl;

  /// Tracks which fields should flash on package selection.
  bool _isFlashingTotal = false;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _brideCtrl.dispose();
    _groomCtrl.dispose();
    _coverageCtrl.dispose();
    _extraRateCtrl.dispose();
    _customPriceCtrl.dispose();
    _driveLinkCtrl.dispose();
    _notesCtrl.dispose();
    _totalCtrl.dispose();
    _advanceCtrl.dispose();
    _companyNameCtrl.dispose();
    _locationCtrl.dispose();
    _reportingTimeCtrl.dispose();
    _chiefNameCtrl.dispose();
    _mapLinkCtrl.dispose();
    _requirementsCtrl.dispose();
    _flashCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _seedFrom(BookingDraft draft) {
    _titleCtrl.text = draft.title;
    _clientNameCtrl.text = draft.clientName ?? '';
    _clientPhoneCtrl.text = draft.clientPhone ?? '';
    _companyNameCtrl.text = draft.clientName ?? '';
    _venueCtrl.text = draft.venue ?? '';
    _brideCtrl.text = draft.brideName ?? '';
    _groomCtrl.text = draft.groomName ?? '';
    _coverageCtrl.text = draft.coverageHours?.toString() ?? '';
    _extraRateCtrl.text = draft.extraHourRate?.toString() ?? '';
    _customPriceCtrl.text = draft.customPrice?.toString() ?? '';
    _driveLinkCtrl.text = draft.driveLink ?? '';
    _notesCtrl.text = draft.notes ?? '';
    if (draft.customPrice != null) {
      _totalCtrl.text = draft.customPrice!.toStringAsFixed(0);
    } else {
      _totalCtrl.clear();
    }
    _advanceCtrl.clear();
    if (draft.chiefPhotographerUserId != null) {
      _chiefNameCtrl.text = draft.chiefPhotographerUserId!;
    }
    _chiefEnabled = draft.chiefPhotographerUserId != null;
    _mapLinkCtrl.text = draft.mapLink ?? '';
    _requirementsCtrl.text = draft.requirementsNote ?? '';
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    final controllerProv = bookingEditControllerProvider(widget.bookingId);
    final draftAsync = ref.watch(controllerProv);
    final loc = AppLocalizations.of(context);
    final policy = ref.watch(bookingsPolicyProvider);

    final isCreate = widget.bookingId == null;
    final required = isCreate
        ? Capability.createBooking
        : Capability.editBooking;
    if (!policy.can(required)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscard();
        if (!mounted) return;
        if (shouldDiscard) {
          Navigator.of(this.context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.voidBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: AppColors.film),
            tooltip: loc.bookings_cancel,
            onPressed: () async {
              final shouldDiscard = !_dirty || await _confirmDiscard();
              if (!mounted) return;
              if (shouldDiscard) Navigator.of(this.context).maybePop();
            },
          ),
          title: Text(
            isCreate
                ? loc.bookings_new_booking_screen
                : loc.bookings_edit_booking_screen,
            style: TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Saving happens only through the sticky "Create Booking" /
          // "Save Changes" bar below — the duplicate appbar SAVE was removed.
        ),
        body: SafeArea(
          child: draftAsync.when(
            loading: () => const Center(child: LensLoader()),
            error: (err, _) => Center(
              child: ErrorState(
                message: 'Could not open the booking editor.',
                onRetry: () => ref.invalidate(controllerProv),
              ),
            ),
            data: (draft) {
              if (!_seeded) _seedFrom(draft);
              return Column(
                children: [
                  _buildStickySaveBar(draft, loc, policy),
                  Expanded(child: _buildForm(context, draft, policy.role)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStickySaveBar(
    BookingDraft draft,
    AppLocalizations loc,
    RolePolicy policy,
  ) {
    final isOwnerMode =
        policy.role == UserRole.owner ||
        (policy.role == UserRole.both && !_showFreelancerForm);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.voidElevated,
        border: Border(
          bottom: BorderSide(
            color: AppColors.line(0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (context, child) {
                final shake = _shakeCtrl.value > 0
                    ? math.sin(_shakeCtrl.value * math.pi * 2) * 4
                    : 0.0;
                return Transform.translate(
                  offset: Offset(shake, 0),
                  child: FilledButton.icon(
                    onPressed: _onSave,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      widget.bookingId == null
                          ? loc.bookings_create
                          : loc.bookings_save_changes,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.voidBlack,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isOwnerMode && policy.role != UserRole.freelancer) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _hidePaymentVisible
                    ? AppColors.line(0.06)
                    : AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _hidePaymentVisible = !_hidePaymentVisible),
                child: Icon(
                  _hidePaymentVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _hidePaymentVisible
                      ? AppColors.filmMuted
                      : AppColors.gold,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, BookingDraft draft, UserRole role) {
    final policy = ref.read(bookingsPolicyProvider);

    final isBothRole = role == UserRole.both;
    final showFreelancer = isBothRole && _showFreelancerForm;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        if (isBothRole) ...[_buildModePicker(), const SizedBox(height: 12)],
        if (showFreelancer)
          _buildFreelancerForm(context, draft, policy)
        else
          _buildOwnerForm(context, draft, policy),
      ],
    );
  }

  Widget _buildModePicker() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.line(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModePill(
              label: 'Freelancer',
              icon: Icons.camera_alt_outlined,
              selected: _showFreelancerForm,
              onTap: () {
                setState(() => _showFreelancerForm = true);
                ref
                    .read(
                      bookingEditControllerProvider(widget.bookingId).notifier,
                    )
                    .setFreelancerMode(true);
              },
            ),
          ),
          Expanded(
            child: _ModePill(
              label: 'Owner',
              icon: Icons.business_center_outlined,
              selected: !_showFreelancerForm,
              onTap: () {
                setState(() => _showFreelancerForm = false);
                ref
                    .read(
                      bookingEditControllerProvider(widget.bookingId).notifier,
                    )
                    .setFreelancerMode(false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerForm(
    BuildContext context,
    BookingDraft draft,
    RolePolicy policy,
  ) {
    final controller = ref.read(
      bookingEditControllerProvider(widget.bookingId).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Client Name
        LensTextField(
          label: 'Client Name',
          controller: _clientNameCtrl,
          hint: 'e.g. Rahat & Tasnim',
          errorText: _validation.errorFor(BookingField.client),
          onChanged: (v) {
            _markDirty();
            controller.setClientName(v.trim().isEmpty ? null : v);
          },
        ),
        // 2. Client Phone
        LensTextField(
          label: 'Client Phone',
          controller: _clientPhoneCtrl,
          hint: '+880 1XXXXXXXXX',
          keyboardType: TextInputType.phone,
          errorText: _validation.errorFor(BookingField.clientPhone),
          onChanged: (v) {
            _markDirty();
            controller.setClientPhone(v.trim().isEmpty ? null : v);
          },
        ),
        // 3. Shift (before Date per v12 spec)
        _buildShiftPills(draft, controller),
        // 4. Date
        LensPickerRow(
          label: 'Date',
          icon: Icons.event_outlined,
          valueText: draft.date == null
              ? null
              : DateFormat.yMMMEd().format(draft.date!),
          placeholder: 'Pick a date',
          errorText: _validation.errorFor(BookingField.date),
          onTap: () => _pickDate(draft, controller),
        ),
        // 5. Venue
        LensTextField(
          label: 'Venue',
          controller: _venueCtrl,
          hint: 'Garden Hall, Banani',
          onChanged: (v) {
            _markDirty();
            controller.setVenue(v.isEmpty ? null : v);
          },
        ),
        // 5b. Optional venue map link — tap the pin to open the maps app.
        _buildMapLinkField(controller),
        // 6. Package
        _buildPackageSection(draft, controller),
        // 7. Outdoor toggle → conditional Location + Time fields
        LensSwitchTile(
          label: 'Outdoor shoot',
          subtitle: 'Affects gear / weather planning.',
          value: draft.outdoor,
          onChanged: (v) {
            _markDirty();
            controller.setOutdoor(v);
          },
        ),
        if (draft.outdoor) ...[
          LensTextField(
            label: 'Outdoor Location',
            controller: _locationCtrl,
            hint: 'Beach, park, etc.',
            onChanged: (_) => _markDirty(),
          ),
          LensTextField(
            label: 'Reporting Time',
            controller: _reportingTimeCtrl,
            hint: 'e.g. 07:00 AM',
            onChanged: (_) => _markDirty(),
          ),
        ],
        // 8. Chief Photographer toggle (gold accent)
        _buildChiefSection(draft, controller),
        // 9. Quick-add team section
        _buildQuickTeamSection(draft, controller),
        // 10. Event Type
        _buildEventTypeSection(draft, controller),
        // 11. Bride/Groom (conditional on wedding/holud)
        if (draft.eventType.requiresBrideGroom) ...[
          LensTextField(
            label: 'Bride',
            controller: _brideCtrl,
            hint: 'Optional',
            onChanged: (v) {
              _markDirty();
              controller.setBrideName(v.isEmpty ? null : v);
            },
          ),
          LensTextField(
            label: 'Groom',
            controller: _groomCtrl,
            hint: 'Optional',
            onChanged: (v) {
              _markDirty();
              controller.setGroomName(v.isEmpty ? null : v);
            },
          ),
        ],
        // 12. Payment (Total / Advance / Due)
        _buildPaymentSection(draft, controller, policy),
        // 13. Client Requirements — optional free text (prints, album,
        // pendrive, delivery system, …).
        LensTextField(
          label: 'Client Requirements (optional)',
          controller: _requirementsCtrl,
          hint: 'Print, album, pendrive, delivery system…',
          maxLines: 3,
          onChanged: (v) {
            _markDirty();
            controller.setRequirementsNote(v.isEmpty ? null : v);
          },
        ),
        // 14. Notes
        LensTextField(
          label: 'Notes',
          controller: _notesCtrl,
          maxLines: 3,
          onChanged: (v) {
            _markDirty();
            controller.setNotes(v.isEmpty ? null : v);
          },
        ),
        // 15. Hide payment from team
        if (policy.can(Capability.toggleHidePayment))
          LensSwitchTile(
            label: 'Hide payment from team',
            subtitle:
                'Manager and Freelancer roles will not see payment or payout fields.',
            value: draft.hidePaymentFromTeam,
            onChanged: (v) {
              _markDirty();
              controller.setHidePaymentFromTeam(v);
            },
          ),
        // 15b. Show payment on shared event details (owner opt-in).
        if (policy.can(Capability.toggleHidePayment))
          LensSwitchTile(
            label: 'Show payment in shared details',
            subtitle:
                'Off by default. When on, Total / Advance / Due appear on the '
                'event details you share with the team and freelancers.',
            value: draft.showPaymentInShare,
            onChanged: (v) {
              _markDirty();
              controller.setShowPaymentInShare(v);
            },
          ),
        // 16. Assignments editor
        AssignmentsEditor(
          draft: draft,
          bookingId: widget.bookingId,
          showPayout:
              !(draft.hidePaymentFromTeam &&
                  policy.role != UserRole.owner &&
                  policy.role != UserRole.both),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFreelancerForm(
    BuildContext context,
    BookingDraft draft,
    RolePolicy policy,
  ) {
    final controller = ref.read(
      bookingEditControllerProvider(widget.bookingId).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LensTextField(
          label: 'Company Name',
          controller: _companyNameCtrl,
          hint: 'Studio or brand name',
          onChanged: (v) {
            _markDirty();
            // Freelancer's "company" is the client they're shooting for —
            // store it in clientName so the short-form persists too.
            controller.setClientName(v.trim().isEmpty ? null : v);
          },
        ),
        LensPickerRow(
          label: 'Date',
          icon: Icons.event_outlined,
          valueText: draft.date == null
              ? null
              : DateFormat.yMMMEd().format(draft.date!),
          placeholder: 'Pick a date',
          errorText: _validation.errorFor(BookingField.date),
          onTap: () => _pickDate(draft, controller),
        ),
        _buildShiftPills(draft, controller),
        LensSwitchTile(
          label: 'Outdoor shoot',
          subtitle: 'Affects gear / weather planning.',
          value: draft.outdoor,
          onChanged: (v) {
            _markDirty();
            controller.setOutdoor(v);
          },
        ),
        if (draft.outdoor) ...[
          LensTextField(
            label: 'Location',
            controller: _locationCtrl,
            hint: 'Outdoor location details',
            onChanged: (_) => _markDirty(),
          ),
          LensTextField(
            label: 'Reporting Time',
            controller: _reportingTimeCtrl,
            hint: 'e.g. 08:00 AM',
            onChanged: (_) => _markDirty(),
          ),
        ],
        _buildMapLinkField(controller),
        _buildEventTypeSection(draft, controller),
        LensTextField(
          label: 'Notes',
          controller: _notesCtrl,
          maxLines: 3,
          onChanged: (v) {
            _markDirty();
            controller.setNotes(v.isEmpty ? null : v);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildShiftPills(
    BookingDraft draft,
    BookingEditController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: Shift.values.map((shift) {
          final isSelected = draft.shift == shift;
          final label = switch (shift) {
            Shift.day => 'Day 12–5',
            Shift.night => 'Night 6–11',
            Shift.both => 'Full Day',
          };
          // Compact single-row pills — the old stacked icon+label cards
          // took ~3x the vertical space they needed.
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _markDirty();
                controller.setShift(shift);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: shift != Shift.both ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                decoration: BoxDecoration(
                  // Selected = solid teal so the white label/icon is readable
                  // and it's obvious which shift is picked.
                  color: isSelected
                      ? AppColors.teal
                      : AppColors.line(0.04),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.teal
                        : AppColors.line(0.08),
                    width: isSelected ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      shift == Shift.night
                          ? Icons.nightlight_outlined
                          : shift == Shift.day
                          ? Icons.wb_sunny_outlined
                          : Icons.brightness_6_outlined,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : AppColors.filmDim.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.filmDim.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPackageSection(
    BookingDraft draft,
    BookingEditController controller,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(
            () => _packageSectionExpanded = !_packageSectionExpanded,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.line(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line(0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: AppColors.filmDim,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PACKAGE',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          letterSpacing: 1.4,
                          color: AppColors.film,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _packageLabel(draft) ?? 'Pick a package',
                        style: TextStyle(
                          color: _packageLabel(draft) != null
                              ? AppColors.film
                              : AppColors.filmMuted.withValues(alpha: 0.7),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _packageSectionExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.filmMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LensPickerRow(
              label: 'Select Package',
              icon: Icons.inventory_2_outlined,
              valueText: _packageLabel(draft),
              placeholder: 'Choose a package',
              onTap: () => _pickPackage(draft, controller),
            ),
          ),
          crossFadeState: _packageSectionExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (draft.packageId == null)
          LensTextField(
            label: 'Custom Price',
            controller: _customPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: _validation.errorFor(BookingField.customPrice),
            onChanged: (v) {
              _markDirty();
              controller.setCustomPrice(double.tryParse(v));
            },
          ),
      ],
    );
  }

  Widget _buildEventTypeSection(
    BookingDraft draft,
    BookingEditController controller,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _eventTypesExpanded = !_eventTypesExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.line(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line(0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.celebration_outlined,
                  size: 18,
                  color: AppColors.filmDim,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EVENT TYPE',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          letterSpacing: 1.4,
                          color: AppColors.film,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _titleCase(draft.eventType.name),
                        style: TextStyle(
                          color: AppColors.film,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _eventTypesExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.filmMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventType.values.map((type) {
                final isSelected = draft.eventType == type;
                return GestureDetector(
                  onTap: () {
                    _markDirty();
                    controller.setEventType(type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.teal.withValues(alpha: 0.15)
                          : AppColors.line(0.04),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.teal.withValues(alpha: 0.5)
                            : AppColors.line(0.08),
                      ),
                    ),
                    child: Text(
                      _eventTypeChipLabel(type),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.teal
                            : AppColors.filmDim.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState: _eventTypesExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildChiefSection(
    BookingDraft draft,
    BookingEditController controller,
  ) {
    final isEnabled = _chiefEnabled;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.gold.withValues(alpha: 0.06)
                  : AppColors.line(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled
                    ? AppColors.gold.withValues(alpha: 0.35)
                    : AppColors.line(0.08),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHIEF PHOTOGRAPHER',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          letterSpacing: 1.4,
                          color: isEnabled
                              ? AppColors.film
                              : AppColors.filmMuted.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        draft.chiefPhotographerUserId != null
                            ? 'Assigned'
                            : 'Designate a lead photographer',
                        style: TextStyle(
                          color: draft.chiefPhotographerUserId != null
                              ? AppColors.gold
                              : AppColors.filmDim.withValues(alpha: 0.7),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (v) {
                    _markDirty();
                    setState(() => _chiefEnabled = v);
                    if (!v) {
                      controller.setChiefPhotographerUserId(null);
                      _chiefNameCtrl.clear();
                    }
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.gold,
                  inactiveThumbColor: AppColors.filmMuted,
                  inactiveTrackColor: AppColors.line(0.08),
                ),
              ],
            ),
          ),
        ),
        if (isEnabled)
          LensTextField(
            label: 'Chief Photographer Name',
            controller: _chiefNameCtrl,
            hint: 'Type a name or pick from team',
            suffix: IconButton(
              tooltip: 'Pick from team',
              icon: Icon(
                Icons.group_add_outlined,
                color: AppColors.gold,
                size: 20,
              ),
              onPressed: () => _pickChiefFromTeam(controller),
            ),
            onChanged: (v) {
              _markDirty();
              controller.setChiefPhotographerUserId(
                v.trim().isEmpty ? null : v.trim(),
              );
            },
          ),
      ],
    );
  }

  Future<void> _pickChiefFromTeam(BookingEditController controller) async {
    final picked = await TeamMemberPickerSheet.show(
      context,
      title: 'Pick chief photographer',
      multiSelect: false,
      accentColor: AppColors.gold,
    );
    if (picked == null || picked.isEmpty) return;
    final member = picked.first;
    _chiefNameCtrl.text = member.fullName;
    _markDirty();
    controller.setChiefPhotographerUserId(member.fullName);
  }

  /// Optional map link field with a trailing pin that launches the
  /// device's maps app. Accepts a Google-Maps share link or a plain
  /// place name (which is opened as a maps search).
  Widget _buildMapLinkField(BookingEditController controller) {
    return LensTextField(
      label: 'Location Map (optional)',
      controller: _mapLinkCtrl,
      hint: 'Paste a Google Maps link or place name',
      keyboardType: TextInputType.url,
      suffix: IconButton(
        tooltip: 'Open in maps',
        icon: Icon(
          Icons.location_on_outlined,
          color: AppColors.teal,
          size: 20,
        ),
        onPressed: () => _openMapLink(_mapLinkCtrl.text),
      ),
      onChanged: (v) {
        _markDirty();
        controller.setMapLink(v.isEmpty ? null : v);
      },
    );
  }

  Future<void> _openMapLink(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) {
      _showSnack('Add a map link or place name first.');
      return;
    }
    final uri = value.startsWith('http://') || value.startsWith('https://')
        ? Uri.parse(value)
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(value)}',
          );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _showSnack('Could not open the maps app.');
  }

  Widget _buildQuickTeamSection(
    BookingDraft draft,
    BookingEditController controller,
  ) {
    final photoCount = draft.assignments
        .where((a) => a.role == AssignmentRole.photographer)
        .length;
    final cineCount = draft.assignments
        .where((a) => a.role == AssignmentRole.cinematographer)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ADD TEAM',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              letterSpacing: 1.4,
              color: AppColors.film,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Photographer row (teal)
          _TeamAddTile(
            label: 'Photographer',
            icon: Icons.camera_alt_outlined,
            count: photoCount,
            accentColor: AppColors.teal,
            onTap: () => _addTeamMember(
              context,
              controller,
              AssignmentRole.photographer,
            ),
          ),
          const SizedBox(height: 6),
          // Cinematographer row (jelly / purple)
          _TeamAddTile(
            label: 'Cinematographer',
            icon: Icons.videocam_outlined,
            count: cineCount,
            accentColor: AppColors.purple,
            onTap: () => _addTeamMember(
              context,
              controller,
              AssignmentRole.cinematographer,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTeamMember(
    BuildContext context,
    BookingEditController controller,
    AssignmentRole role,
  ) async {
    final roleLabel = switch (role) {
      AssignmentRole.photographer => 'Photographers',
      AssignmentRole.cinematographer => 'Cinematographers',
      _ => role.name,
    };
    final draft = ref
        .read(bookingEditControllerProvider(widget.bookingId))
        .valueOrNull;
    final alreadyAssigned =
        draft?.assignments.map((a) => a.userId).toSet() ?? const <String>{};
    final picked = await TeamMemberPickerSheet.show(
      context,
      title: 'Add $roleLabel',
      excludedUserIds: alreadyAssigned,
      accentColor: role == AssignmentRole.cinematographer
          ? AppColors.purple
          : AppColors.teal,
    );
    if (picked == null || picked.isEmpty) return;
    _markDirty();
    for (final member in picked) {
      controller.addAssignment(userId: member.userId, role: role, payout: 0.0);
    }
  }

  Widget _buildPaymentSection(
    BookingDraft draft,
    BookingEditController controller,
    dynamic policy,
  ) {
    final pkgPrice = _resolvePackagePrice(draft);
    final total = draft.customPrice ?? pkgPrice;
    if (total != null) {
      _totalCtrl.text = total.toStringAsFixed(0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAYMENT',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 10,
            letterSpacing: 1.4,
            color: AppColors.film,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _flashAnim,
          builder: (context, child) {
            final flashValue = _isFlashingTotal ? _flashAnim.value : 0.0;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: flashValue > 0
                    ? AppColors.teal.withValues(alpha: flashValue * 0.08)
                    : AppColors.line(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: flashValue > 0
                      ? AppColors.teal.withValues(alpha: flashValue * 0.4)
                      : AppColors.line(0.08),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LensTextField(
                          label: 'Total',
                          controller: _totalCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (v) {
                            _markDirty();
                            controller.setCustomPrice(double.tryParse(v));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LensTextField(
                          label: 'Advance',
                          controller: _advanceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => _markDirty(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          total != null
                              ? 'Due: ৳${(total - (double.tryParse(_advanceCtrl.text) ?? 0)).toStringAsFixed(0)}'
                              : 'Due: ৳0',
                          style: TextStyle(
                            color: AppColors.filmDim.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  double? _resolvePackagePrice(BookingDraft draft) {
    if (draft.packageId == null) return null;
    final packagesAsync = ref.watch(packagesProvider);
    final pkg = packagesAsync.value
        ?.where((p) => p.id == draft.packageId)
        .firstOrNull;
    return pkg?.basePrice;
  }

  // ────────────────────────── Pickers ──────────────────────────

  Future<void> _pickDate(
    BookingDraft draft,
    BookingEditController controller,
  ) async {
    final initial = draft.date ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.orange,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.film,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.voidElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    _markDirty();
    controller.setDate(picked);
  }

  Future<void> _pickPackage(
    BookingDraft draft,
    BookingEditController controller,
  ) async {
    final result = await _PackagePickerSheet.show(
      context,
      ref: ref,
      currentSelection: draft.packageId,
    );
    if (result == null) return;
    _markDirty();
    if (result.useCustomPrice) {
      controller.setCustomPrice(0);
    } else if (result.package != null) {
      final pkg = result.package!;
      controller.setPackage(
        packageId: pkg.id,
        coverageHours: pkg.coverageHours,
        extraHourRate: pkg.extraHourRate,
      );
      _coverageCtrl.text = pkg.coverageHours?.toString() ?? '';
      _extraRateCtrl.text = pkg.extraHourRate?.toString() ?? '';
      // MOD-25 auto-fill: a package that designates a chief turns the
      // Chief Photographer section on automatically.
      if (pkg.includesChief) {
        setState(() => _chiefEnabled = true);
      }
      _triggerPackageFlash();
      // Surface the package's team composition so the user knows how many
      // photographers / cinematographers to add.
      final parts = <String>[
        if ((pkg.photographerCount ?? 0) > 0)
          '${pkg.photographerCount} photographer${pkg.photographerCount! > 1 ? 's' : ''}',
        if ((pkg.cinematographerCount ?? 0) > 0)
          '${pkg.cinematographerCount} cinematographer${pkg.cinematographerCount! > 1 ? 's' : ''}',
        if (pkg.includesChief) 'chief',
      ];
      if (parts.isNotEmpty && mounted) {
        _showSnack('${pkg.name}: ${parts.join(' · ')} — add the team');
      }
    }
  }

  void _triggerPackageFlash() {
    setState(() {
      _isFlashingTotal = true;
      _packageSectionExpanded = false;
    });
    _flashCtrl.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isFlashingTotal = false);
      });
    });
  }

  String? _packageLabel(BookingDraft draft) {
    if (draft.packageId == null && draft.customPrice == null) return null;
    if (draft.packageId == null) {
      return 'Custom price · ${draft.customPrice?.toStringAsFixed(0) ?? '0'}';
    }
    final packagesAsync = ref.watch(packagesProvider);
    final pkg = packagesAsync.value
        ?.where((p) => p.id == draft.packageId)
        .firstOrNull;
    return pkg?.name ?? 'Package';
  }

  // ────────────────────────── Save / cancel ──────────────────────────

  Future<bool> _confirmDiscard() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          loc.bookings_discard_changes,
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          loc.bookings_discard_body,
          style: TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              loc.bookings_discard_keep,
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.bookings_discard_confirm),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _onSave() async {
    final controller = ref.read(
      bookingEditControllerProvider(widget.bookingId).notifier,
    );
    // Validate up-front so we can shake + show inline errors without
    // attempting a doomed save round-trip.
    final validation = controller.validate();
    if (!validation.isValid) {
      setState(() => _validation = validation);
      _shakeCtrl.forward(from: 0);
      _showSnack('Please fix the highlighted fields.');
      return;
    }
    // Clear any stale inline errors before the save attempt.
    if (_validation.errors.isNotEmpty) {
      setState(() => _validation = const BookingValidation({}));
    }

    // ── Scheduling conflict guard (v12 Key Decisions) ──
    // Freelancer = strict 1 event/shift (hard block). Owner/Both = warning
    // unless Distribution mode is on.
    final draft = ref.read(bookingEditControllerProvider(widget.bookingId)).valueOrNull;
    if (draft != null) {
      final policy = ref.read(bookingsPolicyProvider);
      final existing =
          ref.read(bookingListProvider(const BookingFilter())).valueOrNull ??
          const [];
      // Distribution mode lives in the per-user preferences (Settings).
      final userId = ref.read(currentUserProvider).valueOrNull?.id;
      final distributionOn = userId == null
          ? false
          : await ref
                .read(preferencesRepositoryProvider)
                .getDistributionEnabled(userId);
      if (!mounted) return;
      final conflict = BookingConflict.evaluate(
        role: policy.role,
        freelancerMode: draft.freelancerMode,
        date: draft.date,
        shift: draft.shift,
        candidateId: draft.localId,
        existing: existing,
        distributionOn: distributionOn,
      );
      if (conflict.isBlock) {
        _shakeCtrl.forward(from: 0);
        _showConflictBlocked(conflict.clashingTitle);
        return;
      }
      if (conflict.isWarning) {
        final proceed = await _showConflictWarning(conflict.clashingTitle);
        if (!mounted || !proceed) return;
      }
    }

    try {
      final saved = await controller.save();
      if (!mounted) return;
      final isNewBooking = widget.bookingId == null;
      // 🎉 celebrate a freshly created booking.
      if (isNewBooking) Celebration.confetti(context);
      _showSnack('Saved ✓ — adding to calendar');
      // Schedule (or reschedule) the on-device "1 hour before" reminder.
      // Fire-and-forget — never blocks the save flow.
      EventReminderService.instance.scheduleForBooking(
        bookingId: saved.id,
        title: saved.clientName?.trim().isNotEmpty == true
            ? saved.clientName!.trim()
            : saved.title,
        eventDate: saved.date,
        startTime: saved.startTime,
        venue: saved.venue,
      );
      // MOD-61: a new booking is auto-added to the device calendar. When the
      // user has Auto-sync ON we ONLY do the silent device-calendar write —
      // no Google web page, no manual "Save" tap. With Auto-sync OFF we keep
      // the old behaviour (open the pre-filled page) as a manual fallback.
      if (isNewBooking) {
        final autoSync = await CalendarSyncService.isAutoSyncEnabled();
        await CalendarSyncService.openGoogleCalendar(
          title: saved.title,
          date: saved.date,
          startTime: saved.startTime,
          endTime: saved.endTime,
          venue: saved.venue,
          description: [
            if (saved.clientName != null) 'Client: ${saved.clientName}',
            if (saved.clientPhone != null) 'Phone: ${saved.clientPhone}',
            'Booked via CLICKER PRO',
          ].join('\n'),
          allowWebFallback: !autoSync,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop<Booking>(saved);
    } on BookingValidationException catch (e) {
      if (!mounted) return;
      setState(() => _validation = e.validation);
      _shakeCtrl.forward(from: 0);
      _showSnack('Please fix the highlighted fields.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not save: $e');
    }
  }

  /// Freelancer hard block — same date+shift already booked. No override.
  void _showConflictBlocked(String? clashTitle) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          'This shift is already booked',
          style: TextStyle(color: AppColors.film, fontSize: 18),
        ),
        content: Text(
          'A freelancer can take only one event per shift.'
          '${clashTitle != null ? '\n\nAlready booked this day/shift: "$clashTitle".' : ''}\n\n'
          'To take multiple events in a shift, turn on Settings → Distribution. '
          'Otherwise change the existing booking or pick another shift/date.',
          style: TextStyle(color: AppColors.filmDim, fontSize: 13.5),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Owner/Both warning — same date+shift already booked, override allowed.
  /// Returns true if the user chooses to save anyway.
  Future<bool> _showConflictWarning(String? clashTitle) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          'This shift is already booked',
          style: TextStyle(color: AppColors.film, fontSize: 18),
        ),
        content: Text(
          '${clashTitle != null ? '"$clashTitle" — ' : ''}there is already an event on this day/shift.\n\n'
          'To take multiple events at once, turn on Profile → Distribution mode.\n\n'
          'Save this booking anyway?',
          style: TextStyle(color: AppColors.filmDim, fontSize: 13.5),
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
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Yes, save'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.voidElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Pickers (bottom sheets)
// ─────────────────────────────────────────────────────────────────────

class _PackagePickerResult {
  const _PackagePickerResult({this.package, this.useCustomPrice = false});
  final Package? package;
  final bool useCustomPrice;
}

class _PackagePickerSheet extends ConsumerWidget {
  const _PackagePickerSheet({this.currentSelection});
  final String? currentSelection;

  static Future<_PackagePickerResult?> show(
    BuildContext context, {
    required WidgetRef ref,
    required String? currentSelection,
  }) {
    return showModalBottomSheet<_PackagePickerResult>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      builder: (_) => _PackagePickerSheet(currentSelection: currentSelection),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(packagesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 8),
          Text(
            'Pick a package',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LensLoader(),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Could not load packages.',
                style: TextStyle(color: AppColors.red.withValues(alpha: 0.85)),
              ),
            ),
            data: (packages) => Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: packages.length,
                separatorBuilder: (_, _) => Container(
                  height: 1,
                  color: AppColors.line(0.04),
                ),
                itemBuilder: (_, i) {
                  final p = packages[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      p.name,
                      style: TextStyle(color: AppColors.film, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Base ${p.basePrice.toStringAsFixed(0)}'
                      '${p.coverageHours == null ? '' : ' · ${p.coverageHours}h'}',
                      style: TextStyle(
                        color: AppColors.filmDim.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                    trailing: p.id == currentSelection
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.orange,
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.filmMuted,
                          ),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(_PackagePickerResult(package: p)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(Icons.tune_rounded, color: AppColors.gold),
            label: Text(
              'Use custom price',
              style: TextStyle(color: AppColors.gold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(
              context,
            ).pop(const _PackagePickerResult(useCustomPrice: true)),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.line(0.18),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.5)
                : Colors.transparent,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppColors.teal
                  : AppColors.filmDim.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.teal
                    : AppColors.filmDim.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable team-add tile with accent color + count badge.
class _TeamAddTile extends StatelessWidget {
  const _TeamAddTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '+ $label',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: accentColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

String _eventTypeChipLabel(EventType type) {
  return switch (type) {
    EventType.wedding => 'Wedding',
    EventType.holud => 'Holud',
    EventType.birthday => 'Birthday',
    EventType.corporate => 'Corporate',
    EventType.preWedding => 'Pre-Wedding',
    EventType.anniversary => 'Anniversary',
    EventType.outdoor => 'Outdoor',
    EventType.other => 'Other',
  };
}

String _titleCase(String input) {
  if (input.isEmpty) return input;
  final spaced = input.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m.group(1)} ${m.group(2)}',
  );
  return spaced
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');
}

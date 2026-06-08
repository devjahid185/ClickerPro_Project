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

import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../auth/domain/user_role.dart';
import '../application/booking_edit_controller.dart';
import '../application/booking_providers.dart';
import '../domain/assignment_role.dart';
import '../domain/booking.dart';
import '../domain/client.dart';
import '../domain/event_type.dart';
import '../domain/package.dart';
import '../domain/shift.dart';
import 'widgets/assignments_editor.dart';
import 'widgets/lens_form_fields.dart';

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

  BookingValidation _validation = const BookingValidation({});
  bool _seeded = false;
  bool _dirty = false;

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
            icon: const Icon(Icons.close_rounded, color: AppColors.film),
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
            style: const TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            AnimatedBuilder(
              animation: _flashAnim,
              builder: (context, child) {
                final flash = _flashAnim.value;
                return TextButton(
                  onPressed: draftAsync.hasValue ? _onSave : null,
                  style: TextButton.styleFrom(
                    backgroundColor: flash > 0
                        ? AppColors.teal.withValues(alpha: flash * 0.15)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    loc.bookings_save,
                    style: TextStyle(
                      color: flash > 0
                          ? Color.lerp(AppColors.film, AppColors.teal, flash)
                          : AppColors.orange,
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
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
            color: Colors.black.withValues(alpha: 0.06),
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
                      textStyle: const TextStyle(
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
                    ? Colors.black.withValues(alpha: 0.06)
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
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModePill(
              label: 'Freelancer',
              icon: Icons.camera_alt_outlined,
              selected: _showFreelancerForm,
              onTap: () => setState(() => _showFreelancerForm = true),
            ),
          ),
          Expanded(
            child: _ModePill(
              label: 'Owner',
              icon: Icons.business_center_outlined,
              selected: !_showFreelancerForm,
              onTap: () => setState(() => _showFreelancerForm = false),
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
        // 13. Client picker (moved after Payment per v12 spec)
        LensPickerRow(
          label: 'Client',
          icon: Icons.person_outline_rounded,
          valueText: _clientLabel(draft),
          placeholder: 'Pick or create a client',
          errorText: _validation.errorFor(BookingField.client),
          onTap: () => _pickClient(draft, controller),
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
            Shift.day => 'Day\n12 – 5',
            Shift.night => 'Night\n6 – 11',
            Shift.both => 'Full Day',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _markDirty();
                controller.setShift(shift);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: shift != Shift.both ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  // Selected = solid teal so the white label/icon is readable
                  // and it's obvious which shift is picked.
                  color: isSelected
                      ? AppColors.teal
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.teal
                        : Colors.black.withValues(alpha: 0.08),
                    width: isSelected ? 1.2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      shift == Shift.night
                          ? Icons.nightlight_outlined
                          : shift == Shift.day
                          ? Icons.wb_sunny_outlined
                          : Icons.brightness_6_outlined,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : AppColors.filmDim.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.filmDim.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        height: 1.3,
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
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(
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
                          color: AppColors.gold.withValues(alpha: 0.85),
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
                  child: const Icon(
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
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(
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
                          color: AppColors.gold.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _titleCase(draft.eventType.name),
                        style: const TextStyle(
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
                  child: const Icon(
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
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.teal.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.08),
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
    final isEnabled = draft.chiefPhotographerUserId != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.gold.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled
                    ? AppColors.gold.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.08),
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
                              ? AppColors.gold
                              : AppColors.filmMuted.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEnabled
                            ? 'Assigned'
                            : 'Designate a lead photographer',
                        style: TextStyle(
                          color: isEnabled
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
                    if (!v) {
                      controller.setChiefPhotographerUserId(null);
                      _chiefNameCtrl.clear();
                    }
                    // When toggled on, the text field appears below
                    setState(() {});
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.gold,
                  inactiveThumbColor: AppColors.filmMuted,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
          ),
        ),
        if (isEnabled)
          LensTextField(
            label: 'Chief ID',
            controller: _chiefNameCtrl,
            hint: 'Paste chief photographer user ID',
            onChanged: (v) {
              _markDirty();
              controller.setChiefPhotographerUserId(v.isEmpty ? null : v);
            },
          ),
      ],
    );
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
              color: AppColors.gold.withValues(alpha: 0.85),
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
      AssignmentRole.photographer => 'Photographer',
      AssignmentRole.cinematographer => 'Cinematographer',
      _ => role.name,
    };
    final userId = await _QuickMemberDialog.show(context, roleLabel: roleLabel);
    if (userId == null || userId.isEmpty) return;
    controller.addAssignment(userId: userId, role: role, payout: 0.0);
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
            color: AppColors.gold.withValues(alpha: 0.85),
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
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: flashValue > 0
                      ? AppColors.teal.withValues(alpha: flashValue * 0.4)
                      : Colors.black.withValues(alpha: 0.08),
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
          dialogTheme: const DialogThemeData(
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

  Future<void> _pickClient(
    BookingDraft draft,
    BookingEditController controller,
  ) async {
    final picked = await _ClientPickerSheet.show(
      context,
      ref: ref,
      currentStudioId: draft.studioId,
    );
    if (picked == null) return;
    _markDirty();
    controller.setClientId(picked);
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
      controller.setPackage(
        packageId: result.package!.id,
        coverageHours: result.package!.coverageHours,
        extraHourRate: result.package!.extraHourRate,
      );
      _coverageCtrl.text = result.package!.coverageHours?.toString() ?? '';
      _extraRateCtrl.text = result.package!.extraHourRate?.toString() ?? '';
      _triggerPackageFlash();
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

  String? _clientLabel(BookingDraft draft) {
    final clientId = draft.clientId;
    // No linked client id: fall back to the booking's own client name/phone.
    if (clientId == null || clientId.isEmpty) {
      final name = draft.clientName?.trim();
      if (name != null && name.isNotEmpty) {
        final phone = draft.clientPhone?.trim();
        return (phone != null && phone.isNotEmpty) ? '$name · $phone' : name;
      }
      return null;
    }
    final clientAsync = ref.watch(clientByIdProvider(clientId));
    final c = clientAsync.value;
    // BUG-FIX: a clientId that resolves to no client (e.g. a stale/placeholder
    // id like 'pending' on older rows) must NOT be shown raw. Prefer the
    // booking's own clientName/clientPhone; only then give nothing.
    if (c == null) {
      final name = draft.clientName?.trim();
      if (name != null && name.isNotEmpty) {
        final phone = draft.clientPhone?.trim();
        return (phone != null && phone.isNotEmpty) ? '$name · $phone' : name;
      }
      return null;
    }
    return '${c.name} · ${c.phone}';
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
          style: const TextStyle(color: AppColors.film),
        ),
        content: Text(
          loc.bookings_discard_body,
          style: const TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              loc.bookings_discard_keep,
              style: const TextStyle(color: AppColors.filmDim),
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
    try {
      final saved = await controller.save();
      if (!mounted) return;
      _showSnack('Saved ✓');
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

class _ClientPickerSheet extends ConsumerStatefulWidget {
  const _ClientPickerSheet({required this.studioId});
  final String studioId;

  static Future<String?> show(
    BuildContext context, {
    required WidgetRef ref,
    required String currentStudioId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      builder: (_) => _ClientPickerSheet(studioId: currentStudioId),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    );
  }

  @override
  ConsumerState<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends ConsumerState<_ClientPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Client> _results = const [];

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    final repo = ref.read(clientRepositoryProvider);
    final list = await repo.searchByPhone(q);
    if (!mounted) return;
    setState(() => _results = list);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 8),
            const Text(
              'Pick a client',
              style: TextStyle(
                color: AppColors.film,
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            LensTextField(
              label: 'Search by phone',
              controller: _searchCtrl,
              keyboardType: TextInputType.phone,
              hint: 'Type a phone number',
              prefixIcon: Icons.search,
              onChanged: _runSearch,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _results.isEmpty
                  ? _NoResults(
                      onCreate: () => _onCreateInline(_searchCtrl.text.trim()),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => Container(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                      itemBuilder: (_, i) {
                        final c = _results[i];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              color: AppColors.film,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            c.phone,
                            style: TextStyle(
                              color: AppColors.filmDim.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.filmMuted,
                          ),
                          onTap: () => Navigator.of(context).pop(c.id),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add, color: AppColors.orange),
              label: const Text(
                'Create new client',
                style: TextStyle(color: AppColors.orange),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.orange.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _onCreateInline(_searchCtrl.text.trim()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCreateInline(String prefilledPhone) async {
    final created = await _CreateClientDialog.show(
      context,
      studioId: widget.studioId,
      prefillPhone: prefilledPhone,
    );
    if (created == null) return;
    final saved = await ref.read(clientRepositoryProvider).save(created);
    if (!mounted) return;
    Navigator.of(context).pop(saved.id);
  }
}

class _CreateClientDialog extends StatefulWidget {
  const _CreateClientDialog({
    required this.studioId,
    required this.prefillPhone,
  });

  final String studioId;
  final String prefillPhone;

  static Future<Client?> show(
    BuildContext context, {
    required String studioId,
    required String prefillPhone,
  }) {
    return showDialog<Client>(
      context: context,
      builder: (_) =>
          _CreateClientDialog(studioId: studioId, prefillPhone: prefillPhone),
    );
  }

  @override
  State<_CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends State<_CreateClientDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController(text: widget.prefillPhone);
    _email = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.voidElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New client',
              style: TextStyle(
                color: AppColors.film,
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            LensTextField(
              label: 'Name',
              controller: _name,
              maxLength: 80,
              errorText: _nameError,
              onChanged: (_) => _clearErrors(),
            ),
            LensTextField(
              label: 'Phone',
              controller: _phone,
              keyboardType: TextInputType.phone,
              errorText: _phoneError,
              onChanged: (_) => _clearErrors(),
            ),
            LensTextField(
              label: 'Email (optional)',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.filmDim),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _onCreate,
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearErrors() {
    if (_nameError != null || _phoneError != null) {
      setState(() {
        _nameError = null;
        _phoneError = null;
      });
    }
  }

  void _onCreate() {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    String? nameErr;
    String? phoneErr;
    if (name.isEmpty) nameErr = 'Name is required.';
    if (name.length > 80) nameErr = 'Name must be 80 characters or fewer.';
    if (phone.isEmpty) {
      phoneErr = 'Phone is required.';
    } else if (!RegExp(r'^\+?\d+$').hasMatch(phone)) {
      phoneErr = 'Phone must be digits.';
    }
    if (nameErr != null || phoneErr != null) {
      setState(() {
        _nameError = nameErr;
        _phoneError = phoneErr;
      });
      return;
    }
    final now = DateTime.now();
    Navigator.of(context).pop(
      Client(
        id: 'c-${now.microsecondsSinceEpoch}',
        studioId: widget.studioId,
        name: name,
        phone: phone,
        email: email.isEmpty ? null : email,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

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
          const Text(
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
                  color: Colors.black.withValues(alpha: 0.04),
                ),
                itemBuilder: (_, i) {
                  final p = packages[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      p.name,
                      style: const TextStyle(color: AppColors.film, fontSize: 14),
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
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.orange,
                          )
                        : const Icon(
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
            icon: const Icon(Icons.tune_rounded, color: AppColors.gold),
            label: const Text(
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

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_outlined,
            color: AppColors.filmMuted.withValues(alpha: 0.85),
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            'No matching clients yet.',
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.85),
              fontSize: 13,
            ),
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
          color: Colors.black.withValues(alpha: 0.18),
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

/// Quick-add team member dialog — asks only for a user ID.
class _QuickMemberDialog extends StatefulWidget {
  const _QuickMemberDialog({required this.roleLabel});
  final String roleLabel;

  static Future<String?> show(
    BuildContext context, {
    required String roleLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _QuickMemberDialog(roleLabel: roleLabel),
    );
  }

  @override
  State<_QuickMemberDialog> createState() => _QuickMemberDialogState();
}

class _QuickMemberDialogState extends State<_QuickMemberDialog> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.voidElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add ${widget.roleLabel}',
              style: const TextStyle(
                color: AppColors.film,
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            LensTextField(
              label: 'User ID',
              controller: _ctrl,
              hint: 'Paste team member user ID',
              errorText: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.filmDim),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.voidBlack,
                    ),
                    onPressed: () {
                      final val = _ctrl.text.trim();
                      if (val.isEmpty) {
                        setState(() => _error = 'User ID is required.');
                        return;
                      }
                      Navigator.of(context).pop(val);
                    },
                    child: const Text('Add'),
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
    EventType.preWedding => 'Portrait',
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

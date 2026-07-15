// lib/features/bookings/application/booking_edit_controller.dart
//
// AsyncNotifier family that backs the booking edit screen. The family
// is keyed by the booking's local id; pass `null` for a fresh draft.
//
// The controller holds an immutable [BookingDraft] in [state] and
// exposes `setX` mutators per field plus `save` / `validate` / `resetTo`.
// Each mutator preserves the rest of the draft via `copyWith`, so the
// screen can wire form fields directly to the controller without
// `setState`.
//
// Validation is centralized in [BookingEditController.validate] so the
// screen renders the same error messages the controller would refuse a
// submit on. Validation runs on submit only — per-keystroke validation
// would surface noisy errors before the user has finished typing.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "BookingEditController". Validates Requirements 2.1–2.13.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/validation/phone_validator.dart';
import '../../auth/domain/user_role.dart';
import '../../profile/application/profile_controllers.dart';
import '../domain/assignment.dart';
import '../domain/assignment_role.dart';
import '../domain/booking.dart';
import '../domain/event_type.dart';
import '../domain/shift.dart';
import 'booking_providers.dart';

/// Form-state for the booking edit screen. Built from a [Booking] when
/// editing an existing row, or from defaults when creating a fresh one.
/// Pure data — no Flutter / Riverpod imports.
class BookingDraft {
  const BookingDraft({
    required this.localId,
    required this.studioId,
    required this.createdByUserId,
    required this.createdAt,
    this.remoteId,
    this.title = '',
    this.eventType = EventType.wedding,
    DateTime? date,
    this.startTime = '10:00',
    this.endTime = '18:00',
    this.shift = Shift.day,
    this.venue,
    this.outdoor = false,
    this.brideName,
    this.groomName,
    this.clientId,
    this.clientName,
    this.clientPhone,
    this.packageId,
    this.customPrice,
    this.coverageHours,
    this.extraHourRate,
    this.driveLink,
    this.notes,
    this.hidePaymentFromTeam = false,
    this.showPaymentInShare = false,
    this.chiefPhotographerUserId,
    this.status = BookingStatus.pending,
    this.assignments = const <Assignment>[],
    this.originalAssignmentIds = const <String>{},
    this.clientRequirements,
    this.freelancerMode = false,
  }) : date = date;

  final String localId;
  final String? remoteId;
  final String studioId;
  final String createdByUserId;
  final DateTime createdAt;

  final String title;
  final EventType eventType;
  final DateTime? date;
  final String startTime;
  final String endTime;
  final Shift shift;
  final String? venue;
  final bool outdoor;
  final String? brideName;
  final String? groomName;
  final String? clientId;
  final String? clientName;
  final String? clientPhone;
  final String? packageId;
  final double? customPrice;
  final double? coverageHours;
  final double? extraHourRate;
  final String? driveLink;
  final String? notes;
  final bool hidePaymentFromTeam;
  final bool showPaymentInShare;
  final String? chiefPhotographerUserId;
  final BookingStatus status;

  /// In-memory edit buffer for the booking's assignments. Save persists
  /// each entry through [AssignmentRepository] after the parent
  /// booking commit lands.
  final List<Assignment> assignments;

  /// Snapshot of the assignment ids that existed when the draft was
  /// built. Used at save time to compute the deletions diff (ids that
  /// were present in the original but removed in the draft).
  final Set<String> originalAssignmentIds;

  /// Free-form JSON map carried through from [Booking.clientRequirements].
  /// Holds the optional map link (`mapLink`) and the client requirements
  /// note (`requirementsNote`) plus anything other features stored there
  /// (e.g. the delivery checklist) — preserved verbatim on save.
  final Map<String, dynamic>? clientRequirements;

  /// True while a Both-role user has the FL-12 short form selected.
  /// Validation must NOT demand client name/phone in that mode — the
  /// short form has no phone field, so saving was impossible.
  final bool freelancerMode;

  String? get mapLink => clientRequirements?['mapLink'] as String?;
  String? get requirementsNote =>
      clientRequirements?['requirementsNote'] as String?;

  /// Whether this draft is a brand-new booking (no remoteId AND a
  /// freshly-generated localId).
  bool get isCreate => remoteId == null;

  BookingDraft copyWith({
    String? title,
    EventType? eventType,
    DateTime? date,
    String? startTime,
    String? endTime,
    Shift? shift,
    String? venue,
    bool? outdoor,
    String? brideName,
    String? groomName,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? packageId,
    double? customPrice,
    double? coverageHours,
    double? extraHourRate,
    String? driveLink,
    String? notes,
    bool? hidePaymentFromTeam,
    bool? showPaymentInShare,
    String? chiefPhotographerUserId,
    BookingStatus? status,
    List<Assignment>? assignments,
    Map<String, dynamic>? clientRequirements,
    bool? freelancerMode,
    bool clearPackage = false,
    bool clearCustomPrice = false,
    bool clearClient = false,
    bool clearChief = false,
  }) {
    return BookingDraft(
      localId: localId,
      remoteId: remoteId,
      studioId: studioId,
      createdByUserId: createdByUserId,
      createdAt: createdAt,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shift: shift ?? this.shift,
      venue: venue ?? this.venue,
      outdoor: outdoor ?? this.outdoor,
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      clientId: clearClient ? null : (clientId ?? this.clientId),
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      packageId: clearPackage ? null : (packageId ?? this.packageId),
      customPrice: clearCustomPrice ? null : (customPrice ?? this.customPrice),
      coverageHours: coverageHours ?? this.coverageHours,
      extraHourRate: extraHourRate ?? this.extraHourRate,
      driveLink: driveLink ?? this.driveLink,
      notes: notes ?? this.notes,
      hidePaymentFromTeam: hidePaymentFromTeam ?? this.hidePaymentFromTeam,
      showPaymentInShare: showPaymentInShare ?? this.showPaymentInShare,
      chiefPhotographerUserId: clearChief
          ? null
          : (chiefPhotographerUserId ?? this.chiefPhotographerUserId),
      status: status ?? this.status,
      assignments: assignments ?? this.assignments,
      originalAssignmentIds: originalAssignmentIds,
      clientRequirements: clientRequirements ?? this.clientRequirements,
      freelancerMode: freelancerMode ?? this.freelancerMode,
    );
  }

  /// Materializes this draft into a [Booking] for persistence. The
  /// caller is responsible for stamping `updatedAt = DateTime.now()`
  /// inside the repository.
  Booking toBooking() {
    final resolvedTitle = title.trim().isNotEmpty
        ? title.trim()
        : (clientName?.trim().isNotEmpty == true
              ? clientName!.trim()
              : 'Untitled booking');
    return Booking(
      id: localId,
      remoteId: remoteId,
      studioId: studioId,
      createdByUserId: createdByUserId,
      title: resolvedTitle,
      eventType: eventType,
      date: date ?? DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      shift: shift,
      venue: venue,
      outdoor: outdoor,
      brideName: brideName,
      groomName: groomName,
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      packageId: packageId,
      customPrice: customPrice,
      coverageHours: coverageHours,
      extraHourRate: extraHourRate,
      driveLink: driveLink,
      notes: notes,
      hidePaymentFromTeam: hidePaymentFromTeam,
      showPaymentInShare: showPaymentInShare,
      chiefPhotographerUserId: chiefPhotographerUserId,
      status: status,
      clientRequirements: clientRequirements,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static BookingDraft fromBooking(
    Booking b, {
    List<Assignment> assignments = const <Assignment>[],
  }) => BookingDraft(
    localId: b.id,
    remoteId: b.remoteId,
    studioId: b.studioId,
    createdByUserId: b.createdByUserId,
    createdAt: b.createdAt,
    title: b.title,
    eventType: b.eventType,
    date: b.date,
    startTime: b.startTime,
    endTime: b.endTime,
    shift: b.shift,
    venue: b.venue,
    outdoor: b.outdoor,
    brideName: b.brideName,
    groomName: b.groomName,
    clientId: b.clientId,
    clientName: b.clientName,
    clientPhone: b.clientPhone,
    packageId: b.packageId,
    customPrice: b.customPrice,
    coverageHours: b.coverageHours,
    extraHourRate: b.extraHourRate,
    driveLink: b.driveLink,
    notes: b.notes,
    hidePaymentFromTeam: b.hidePaymentFromTeam,
    showPaymentInShare: b.showPaymentInShare,
    chiefPhotographerUserId: b.chiefPhotographerUserId,
    status: b.status,
    assignments: List<Assignment>.unmodifiable(assignments),
    originalAssignmentIds: assignments.map((a) => a.id).toSet(),
    clientRequirements: b.clientRequirements,
  );
}

/// Result of a one-shot validation pass over a [BookingDraft]. Empty
/// `errors` map = the draft is submittable.
class BookingValidation {
  const BookingValidation(this.errors);
  final Map<BookingField, String> errors;

  bool get isValid => errors.isEmpty;
  String? errorFor(BookingField f) => errors[f];

  /// Returns a copy with [f]'s error cleared — used to drop an inline error
  /// the moment the user fixes that field.
  BookingValidation withoutField(BookingField f) {
    if (!errors.containsKey(f)) return this;
    final next = Map<BookingField, String>.from(errors)..remove(f);
    return BookingValidation(next);
  }
}

/// Identifies a single field on the booking form. Used as the key for
/// validation errors so the screen can map errors back to inline UI.
enum BookingField {
  title,
  date,
  startTime,
  endTime,
  shift,
  client,
  clientPhone,
  eventType,
  brideName,
  groomName,
  driveLink,
  customPrice,
  advance,
}

class BookingEditController
    extends AutoDisposeFamilyAsyncNotifier<BookingDraft, String?> {
  @override
  Future<BookingDraft> build(String? bookingLocalId) async {
    // Read the cached current user via the Drift-backed
    // `currentUserProvider`. We deliberately use this stream rather
    // than `sessionControllerProvider` so the editor stays usable when
    // the session controller is still resolving (e.g. on cold boot).
    // Tests can override `currentUserProvider` directly to seed a user
    // without spinning up the full auth stack.
    //
    // We `await ... .future` so the controller waits for the stream's
    // first emission rather than reading the synchronous `.value` —
    // otherwise, on the very first frame after the screen mounts the
    // value will still be `null` and the editor would error out.
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      throw StateError(
        'Cannot open the booking editor without an authenticated session.',
      );
    }

    if (bookingLocalId != null) {
      // Edit mode — load the existing booking from the local store.
      final existing = await ref
          .read(bookingRepositoryProvider)
          .getById(bookingLocalId);
      // Pull the booking's assignments alongside so the editor opens
      // with the live edit buffer pre-populated.
      final assignments = await ref
          .read(assignmentRepositoryProvider)
          .watchByBooking(bookingLocalId)
          .first;
      return BookingDraft.fromBooking(existing, assignments: assignments);
    }

    // Create mode — fresh draft.
    final now = DateTime.now();
    final newId = 'b-${now.microsecondsSinceEpoch}';
    final studioId = (user.role == UserRole.owner || user.role == UserRole.both)
        ? user.id
        : (user.ownerId ?? user.id);
    // A pure Freelancer can only log their OWN short-form bookings (FL-12),
    // so a fresh draft must start in freelancer mode — otherwise the editor
    // shows the freelancer form but validates/saves against the full studio
    // form and the "+ Add Booking" action appears to do nothing.
    final isFreelancer = user.role == UserRole.freelancer;
    return BookingDraft(
      localId: newId,
      studioId: studioId,
      createdByUserId: user.id,
      createdAt: now,
      date: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      // Default to the Day shift's canonical window (12pm–5pm) so a
      // freshly created booking already carries sane times before the
      // user touches the shift pills.
      startTime: Shift.day.defaultStartTime,
      endTime: Shift.day.defaultEndTime,
      freelancerMode: isFreelancer,
    );
  }

  // ────────────────────────── Field setters ──────────────────────────

  void setTitle(String value) => _update((d) => d.copyWith(title: value));
  void setEventType(EventType value) =>
      _update((d) => d.copyWith(eventType: value));
  void setDate(DateTime value) => _update((d) => d.copyWith(date: value));
  void setStartTime(String value) =>
      _update((d) => d.copyWith(startTime: value));
  void setEndTime(String value) => _update((d) => d.copyWith(endTime: value));

  /// Picking a shift also stamps the booking's canonical times so the
  /// calendar entry, dashboard "today" bucketing, and the chronology
  /// guard all line up with the agreed schedule (Day 12pm–5pm,
  /// Night 6pm–11pm).
  void setShift(Shift value) => _update(
    (d) => d.copyWith(
      shift: value,
      startTime: value.defaultStartTime,
      endTime: value.defaultEndTime,
    ),
  );
  void setVenue(String? value) => _update((d) => d.copyWith(venue: value));
  void setOutdoor(bool value) => _update((d) => d.copyWith(outdoor: value));
  void setBrideName(String? value) =>
      _update((d) => d.copyWith(brideName: value));
  void setGroomName(String? value) =>
      _update((d) => d.copyWith(groomName: value));
  void setClientId(String? value) {
    _update(
      (d) => value == null
          ? d.copyWith(clearClient: true)
          : d.copyWith(clientId: value),
    );
  }

  /// MOD-07 v6: Client Name is a direct required form field.
  void setClientName(String? value) =>
      _update((d) => d.copyWith(clientName: value));

  /// MOD-07 v6: Client Phone — required for Owner/Both modes.
  void setClientPhone(String? value) =>
      _update((d) => d.copyWith(clientPhone: value));

  /// Picks an existing package. Selecting a package clears any custom
  /// price; the screen pre-fills coverage hours / extra hour rate from
  /// the package automatically.
  void setPackage({
    required String packageId,
    double? coverageHours,
    double? extraHourRate,
  }) {
    _update(
      (d) => d.copyWith(
        packageId: packageId,
        coverageHours: coverageHours,
        extraHourRate: extraHourRate,
        clearCustomPrice: true,
      ),
    );
  }

  /// Switches to a custom-price booking; clears any package binding.
  void setCustomPrice(double? value) {
    _update((d) => d.copyWith(customPrice: value, clearPackage: true));
  }

  void setCoverageHours(double? value) =>
      _update((d) => d.copyWith(coverageHours: value));
  void setExtraHourRate(double? value) =>
      _update((d) => d.copyWith(extraHourRate: value));
  void setDriveLink(String? value) =>
      _update((d) => d.copyWith(driveLink: value));
  void setNotes(String? value) => _update((d) => d.copyWith(notes: value));
  void setHidePaymentFromTeam(bool value) =>
      _update((d) => d.copyWith(hidePaymentFromTeam: value));

  /// Owner opt-in: include payment on the shared event details.
  void setShowPaymentInShare(bool value) =>
      _update((d) => d.copyWith(showPaymentInShare: value));

  /// Both-role mode picker: true = FL-12 short form active.
  void setFreelancerMode(bool value) =>
      _update((d) => d.copyWith(freelancerMode: value));

  void setChiefPhotographerUserId(String? value) {
    _update(
      (d) => value == null
          ? d.copyWith(clearChief: true)
          : d.copyWith(chiefPhotographerUserId: value),
    );
  }

  /// Optional Google-Maps (or any) link for the venue. Stored inside
  /// the booking's `clientRequirements` JSON so no schema change is
  /// needed and existing keys (delivery checklist, …) are preserved.
  void setMapLink(String? value) {
    _update((d) {
      final next = <String, dynamic>{...?d.clientRequirements};
      if (value == null || value.trim().isEmpty) {
        next.remove('mapLink');
      } else {
        next['mapLink'] = value.trim();
      }
      return d.copyWith(clientRequirements: next);
    });
  }

  /// Optional free-text client requirements (prints, album, pendrive,
  /// delivery preference, …). Same storage strategy as [setMapLink].
  void setRequirementsNote(String? value) {
    _update((d) {
      final next = <String, dynamic>{...?d.clientRequirements};
      if (value == null || value.trim().isEmpty) {
        next.remove('requirementsNote');
      } else {
        next['requirementsNote'] = value;
      }
      return d.copyWith(clientRequirements: next);
    });
  }

  // ────────────────────────── Assignments ──────────────────────────

  /// Adds a brand-new in-memory assignment to the draft. Persistence
  /// is deferred to [save]. The local id is generated client-side so
  /// the row stays addressable while the user is still editing.
  void addAssignment({
    required String userId,
    required AssignmentRole role,
    double payout = 0.0,
    String? notes,
  }) {
    _update((d) {
      final now = DateTime.now();
      final id = 'a-${now.microsecondsSinceEpoch}';
      final newAssignment = Assignment(
        id: id,
        bookingId: d.localId,
        userId: userId,
        role: role,
        payout: payout,
        notes: notes,
        createdAt: now,
        updatedAt: now,
        pending: true,
      );
      return d.copyWith(
        assignments: List<Assignment>.unmodifiable([
          ...d.assignments,
          newAssignment,
        ]),
      );
    });
  }

  /// Updates an existing draft assignment by id. No-op if the id is
  /// not in the buffer.
  void updateAssignment(
    String assignmentId, {
    String? userId,
    AssignmentRole? role,
    double? payout,
    String? notes,
  }) {
    _update((d) {
      final idx = d.assignments.indexWhere((a) => a.id == assignmentId);
      if (idx < 0) return d;
      final current = d.assignments[idx];
      final next = current.copyWith(
        userId: userId ?? current.userId,
        role: role ?? current.role,
        payout: payout ?? current.payout,
        notes: notes ?? current.notes,
        updatedAt: DateTime.now(),
        pending: true,
      );
      final list = [...d.assignments]..[idx] = next;
      return d.copyWith(assignments: List<Assignment>.unmodifiable(list));
    });
  }

  /// Removes an assignment from the draft buffer. The actual delete
  /// against the repository runs at [save] time, computed via diff
  /// against [BookingDraft.originalAssignmentIds].
  void removeAssignment(String assignmentId) {
    _update((d) {
      final list = d.assignments
          .where((a) => a.id != assignmentId)
          .toList(growable: false);
      if (list.length == d.assignments.length) return d;
      return d.copyWith(assignments: List<Assignment>.unmodifiable(list));
    });
  }

  // ────────────────────────── Save / validate ──────────────────────────

  /// Single-shot validation over the current draft. Empty error map =
  /// the draft is submittable. Per MOD-07 v6: Client Name + Date are
  /// always required; Client Phone is required in Owner/Both modes.
  /// Freelancer short-form only requires Date (+ shift, always set).
  BookingValidation validate() {
    final draft = state.valueOrNull;
    if (draft == null) {
      return const BookingValidation({BookingField.title: 'Loading…'});
    }
    final errors = <BookingField, String>{};

    final policy = ref.read(bookingsPolicyProvider);
    final isOwnerMode =
        (policy.role == UserRole.owner || policy.role == UserRole.both) &&
        !draft.freelancerMode;

    if (draft.date == null) {
      errors[BookingField.date] = 'Date is required.';
    }

    // Heaven 2026-07-15: "নাম, নাম্বার, ডেট, সিফট না দিলে বুকিং হবে না" —
    // name + phone + date are hard requirements (shift always carries a
    // value); the Owner form additionally needs a package or price (advance
    // is enforced by the screen, which owns that field).
    if (isOwnerMode) {
      if (draft.clientName == null || draft.clientName!.trim().isEmpty) {
        errors[BookingField.client] = 'Client name is required.';
      }
      if (draft.clientPhone == null || draft.clientPhone!.trim().isEmpty) {
        errors[BookingField.clientPhone] = 'Client phone is required.';
      } else if (!PhoneValidator.isValid(draft.clientPhone!)) {
        errors[BookingField.clientPhone] =
            'Enter a valid 11-digit number (01XXXXXXXXX).';
      }
      if (draft.packageId == null &&
          (draft.customPrice == null || draft.customPrice! <= 0)) {
        errors[BookingField.customPrice] =
            'Select a package or enter the package price.';
      }
    } else {
      // Freelancer short-form: the typed company name is the booking's
      // identity — required.
      if (draft.clientName == null || draft.clientName!.trim().isEmpty) {
        errors[BookingField.client] = 'Company name is required.';
      }
    }

    return BookingValidation(errors);
  }

  /// Runs validation; on success persists the draft via the repository
  /// and returns the saved booking. The screen pops on success.
  ///
  /// Persistence happens in two steps:
  ///   1. The booking row is committed via `BookingRepository.save`.
  ///   2. Each assignment in the draft buffer is reconciled against
  ///      the original snapshot (added, updated, or removed).
  ///
  /// Throws [BookingValidationException] on invalid input so the screen
  /// can render inline errors without an extra round-trip through the
  /// AsyncValue error tier.
  Future<Booking> save() async {
    final validation = validate();
    if (!validation.isValid) {
      throw BookingValidationException(validation);
    }
    final draft = state.requireValue;
    final policy = ref.read(bookingsPolicyProvider);
    try {
      final saved = await ref
          .read(bookingRepositoryProvider)
          .save(draft.toBooking(), policy: policy);
      // Persist the assignments diff against the original snapshot.
      // We always pass the current policy down — if the role lacks
      // `editAssignment` the repository raises `RolePolicyDeniedException`,
      // which we let bubble up so the UI can render an error.
      await _persistAssignmentDiff(draft: draft, policy: policy);
      // Refresh local state with the latest snapshot of saved data.
      state = AsyncValue.data(
        BookingDraft.fromBooking(saved, assignments: draft.assignments),
      );
      return saved;
    } catch (e, st) {
      AppLogger.e('booking-edit', e, st);
      rethrow;
    }
  }

  /// Diff the draft's assignments against the original snapshot and
  /// commit the resulting create / update / delete operations through
  /// `AssignmentRepository`.
  Future<void> _persistAssignmentDiff({
    required BookingDraft draft,
    required RolePolicy policy,
  }) async {
    final repo = ref.read(assignmentRepositoryProvider);
    final currentIds = draft.assignments.map((a) => a.id).toSet();

    // Deletes — ids that were in the original but are gone from the
    // current buffer.
    for (final originalId in draft.originalAssignmentIds) {
      if (!currentIds.contains(originalId)) {
        await repo.remove(originalId, policy: policy);
      }
    }

    // Adds + updates — anything in the current buffer is replayed.
    // The repository handles upsert semantics: ids unknown to it are
    // treated as creates, known ids as updates.
    for (final assignment in draft.assignments) {
      final isNew = !draft.originalAssignmentIds.contains(assignment.id);
      if (isNew) {
        await repo.add(assignment, policy: policy);
      } else {
        await repo.update(assignment, policy: policy);
      }
    }
  }

  // ────────────────────────── Internals ──────────────────────────

  void _update(BookingDraft Function(BookingDraft) mutate) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(mutate(current));
  }
}

/// Carries the validation result so the screen can show inline errors.
class BookingValidationException implements Exception {
  BookingValidationException(this.validation);
  final BookingValidation validation;

  @override
  String toString() =>
      'BookingValidationException(errors: ${validation.errors})';
}

/// Family-keyed by booking local id (or `null` for create mode).
///
/// `autoDispose` is load-bearing here: without it the create-mode draft
/// (key = `null`) survives the screen being closed, so the next "New
/// Booking" re-opens with the previous client's data still filled in.
final bookingEditControllerProvider = AsyncNotifierProvider.autoDispose
    .family<BookingEditController, BookingDraft, String?>(
      BookingEditController.new,
    );

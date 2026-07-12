// lib/features/public_booking/presentation/public_booking_form_screen.dart
//
// Unauthenticated public booking form. The visitor reaches this screen
// via a deep link — `clickerpro://public/booking?token=...` or the
// equivalent web URL — that carries an HMAC-signed studio-issued token.
//
// Lifecycle:
//
//   1. The screen pulls `publicBookingTokenProvider(token)` to peek at
//      the token. The server returns the studio's branding, supported
//      event types, locale, and expiry.
//   2. On success the form renders, gated to the studio's accepted
//      event types. The visitor fills in title + date + start/end +
//      shift + venue + bride/groom (when applicable) + their own
//      contact info.
//   3. Submit posts back through `PublicBookingRepository.submit`.
//      The server returns a request id; we navigate to a success
//      screen that thanks the visitor.
//
// The flow is intentionally lightweight — no Drift writes, no outbox.
// If the visitor is offline, submit fails and surfaces an inline
// error; we do NOT cache the request locally because the visitor is
// not the device's authenticated user.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Public Booking". Validates Requirements 6.1–6.5.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/booking_format.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/validation/phone_validator.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../bookings/domain/event_type.dart';
import '../../bookings/domain/shift.dart';
import '../../bookings/presentation/widgets/lens_form_fields.dart';
import '../application/public_booking_providers.dart';
import '../domain/public_booking_request.dart';
import '../domain/public_booking_request_status.dart';
import '../domain/public_booking_token.dart';
import 'public_booking_success_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/web_shell.dart';

class PublicBookingFormScreen extends ConsumerWidget {
  const PublicBookingFormScreen({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsync = ref.watch(publicBookingTokenProvider(token));

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Book with us',
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
        child: tokenAsync.when(
          loading: () => const Center(child: LensLoader()),
          error: (err, _) => Center(
            child: ErrorState(
              message: 'This booking link is invalid or expired.',
              onRetry: () => ref.invalidate(publicBookingTokenProvider(token)),
            ),
          ),
          data: (meta) => _Form(token: token, meta: meta),
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.token, required this.meta});
  final String token;
  final PublicBookingToken meta;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _brideCtrl = TextEditingController();
  final _groomCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late EventType _eventType;
  Shift _shift = Shift.day;
  DateTime? _date;
  String _startTime = '10:00';
  String _endTime = '18:00';

  bool _submitting = false;
  String? _topLevelError;
  final Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _eventType = widget.meta.supportedEventTypes.isEmpty
        ? EventType.wedding
        : widget.meta.supportedEventTypes.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    _brideCtrl.dispose();
    _groomCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientEmailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportedTypes = widget.meta.supportedEventTypes.isEmpty
        ? EventType.values
        : widget.meta.supportedEventTypes.toList(growable: false);

    return WebFormWidth(
      maxWidth: 560,
      child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _Header(meta: widget.meta),
        const SizedBox(height: 12),
        if (_topLevelError != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
            ),
            child: Text(
              _topLevelError!,
              style: TextStyle(color: AppColors.red, fontSize: 13),
            ),
          ),
        LensTextField(
          label: 'Event title',
          controller: _titleCtrl,
          hint: 'e.g. Anwar & Sumaiya Wedding',
          errorText: _fieldErrors['title'],
          maxLength: 120,
        ),
        LensSelector<EventType>(
          label: 'Event type',
          value: _eventType,
          items: supportedTypes,
          itemLabel: (e) => _titleCase(e.name),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _eventType = v);
          },
        ),
        LensPickerRow(
          label: 'Date',
          icon: Icons.event_outlined,
          valueText: _date == null ? null : DateFormat.yMMMEd().format(_date!),
          placeholder: 'Pick the event date',
          errorText: _fieldErrors['date'],
          onTap: _pickDate,
        ),
        Row(
          children: [
            Expanded(
              child: LensPickerRow(
                label: 'Start',
                icon: Icons.schedule_outlined,
                valueText: BookingFormat.clockTime(_startTime),
                onTap: () => _pickTime(
                  _startTime,
                  (t) => setState(() => _startTime = t),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LensPickerRow(
                label: 'End',
                icon: Icons.schedule_outlined,
                valueText: BookingFormat.clockTime(_endTime),
                errorText: _fieldErrors['endTime'],
                onTap: () =>
                    _pickTime(_endTime, (t) => setState(() => _endTime = t)),
              ),
            ),
          ],
        ),
        LensSelector<Shift>(
          label: 'Shift',
          value: _shift,
          items: Shift.values,
          itemLabel: (s) => _titleCase(s.name),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _shift = v);
          },
        ),
        LensTextField(
          label: 'Venue',
          controller: _venueCtrl,
          hint: 'Banquet hall name or address',
        ),
        if (_eventType.requiresBrideGroom) ...[
          LensTextField(
            label: 'Bride',
            controller: _brideCtrl,
            errorText: _fieldErrors['bride'],
          ),
          LensTextField(
            label: 'Groom',
            controller: _groomCtrl,
            errorText: _fieldErrors['groom'],
          ),
        ],
        const SizedBox(height: 16),
        const _SectionLabel('Your contact details'),
        LensTextField(
          label: 'Your name',
          controller: _clientNameCtrl,
          errorText: _fieldErrors['clientName'],
        ),
        LensTextField(
          label: 'Phone',
          controller: _clientPhoneCtrl,
          keyboardType: TextInputType.phone,
          errorText: _fieldErrors['clientPhone'],
        ),
        LensTextField(
          label: 'Email (optional)',
          controller: _clientEmailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        LensTextField(
          label: 'Notes',
          controller: _notesCtrl,
          maxLines: 3,
          maxLength: 1000,
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: AppColors.onAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _submitting ? null : _onSubmit,
          child: _submitting
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onAccent,
                  ),
                )
              : const Text(
                  'Submit request',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 14)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.orange,
            onPrimary: AppColors.onAccent,
            surface: AppColors.surface,
            onSurface: AppColors.film,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _fieldErrors.remove('date');
    });
  }

  Future<void> _pickTime(String initial, ValueChanged<String> onPicked) async {
    final parts = initial.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 10,
        minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.orange,
            onPrimary: AppColors.onAccent,
            surface: AppColors.surface,
            onSurface: AppColors.film,
          ),
        ),
        child: MediaQuery(
          // Show the picker in 12-hour AM/PM form (the app-wide convention);
          // the returned TimeOfDay is still stored as canonical "HH:mm".
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        ),
      ),
    );
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    onPicked('$hh:$mm');
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || title.length > 120) {
      errors['title'] = 'Title is required (max 120 chars).';
    }
    if (_date == null) errors['date'] = 'Pick a date.';
    if (_toMinutes(_endTime) < _toMinutes(_startTime)) {
      errors['endTime'] = 'End time cannot be before start time.';
    }
    if (_eventType.requiresBrideGroom) {
      if (_brideCtrl.text.trim().isEmpty) {
        errors['bride'] = 'Bride name is required.';
      }
      if (_groomCtrl.text.trim().isEmpty) {
        errors['groom'] = 'Groom name is required.';
      }
    }
    if (_clientNameCtrl.text.trim().isEmpty) {
      errors['clientName'] = 'Your name is required.';
    }
    final phoneError = PhoneValidator.validate(_clientPhoneCtrl.text);
    if (phoneError != null) {
      errors['clientPhone'] = phoneError;
    }
    return errors;
  }

  Future<void> _onSubmit() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(errors);
        _topLevelError = 'Please fix the highlighted fields.';
      });
      return;
    }
    setState(() {
      _topLevelError = null;
      _fieldErrors.clear();
      _submitting = true;
    });

    final now = DateTime.now();
    final payload = PublicBookingRequest(
      id: 'pending', // server assigns the real id; required field on the wire
      studioId: '', // server fills from token
      title: _titleCtrl.text.trim(),
      eventType: _eventType,
      date: _date!,
      startTime: _startTime,
      endTime: _endTime,
      shift: _shift,
      venue: _trimOrNull(_venueCtrl.text),
      brideName: _eventType.requiresBrideGroom
          ? _trimOrNull(_brideCtrl.text)
          : null,
      groomName: _eventType.requiresBrideGroom
          ? _trimOrNull(_groomCtrl.text)
          : null,
      clientName: _clientNameCtrl.text.trim(),
      clientPhone: _clientPhoneCtrl.text.trim(),
      clientEmail: _trimOrNull(_clientEmailCtrl.text),
      notes: _trimOrNull(_notesCtrl.text),
      status: PublicBookingRequestStatus.pending,
      submittedAt: now,
      updatedAt: now,
    );
    try {
      final repo = ref.read(publicBookingRepositoryProvider);
      final requestId = await repo.submit(
        token: widget.token,
        payload: payload,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        RouteNames.publicBookingSuccess,
        arguments: PublicBookingSuccessArgs(
          requestId: requestId,
          studioName: widget.meta.studioName,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // A status-0 ApiException means the request never reached the server
        // (offline, or the browser blocked a cross-origin call). Show a plain
        // "check your connection" line instead of the raw
        // "ApiException(status: 0, message: Network error)" the client saw.
        final isNetwork = e is ApiException && e.isNetwork;
        _topLevelError = isNetwork
            ? 'Could not submit your request. Please check your internet '
                  'connection and try again.'
            : 'Could not submit your request. Please try again in a moment.';
      });
    }
  }

  String? _trimOrNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.meta});
  final PublicBookingToken meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Container(
                width: 26,
                height: 1.5,
                color: AppColors.orange,
              ),
              const SizedBox(width: 10),
              Text(
                'BOOK YOUR EVENT',
                style: TextStyle(
                  color: AppColors.filmMuted,
                  fontFamily: AppText.monoFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            meta.studioName,
            style: TextStyle(
              color: AppColors.film,
              fontFamily: AppText.brandFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.03,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us about the event you would like us to capture. We will be in touch shortly.',
            style: TextStyle(
              color: AppColors.filmDim,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 1.5,
            color: AppColors.orange,
          ),
          const SizedBox(width: 10),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppText.monoFontFamily,
              fontSize: 10,
              letterSpacing: 0.16,
              color: AppColors.filmMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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

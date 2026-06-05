// lib/core/sync/outbox_worker.dart
//
// Drains the outbox queue against the network. Foundation slice was a
// pure logger; this extension wires:
//
//   • a [BookingsOutboxDispatcher] that routes each row to its API
//     handler and reports back a [DispatchResult]
//   • exponential backoff (2s → 4s → 8s … capped at 300s) with a
//     5-attempt manual-retry cutoff per Requirement 6.5 / 6.9
//   • a single drain loop that holds a re-entrancy guard so the
//     connectivity stream + outbox stream don't kick two loops at the
//     same time
//   • a `Future Function()` clock so tests can fake delays
//
// The worker's `start(connectivity)` is called once from the app boot
// (see `core/providers.dart`); it stays alive for the session and is
// disposed via `stop()`.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../logging/app_logger.dart';
import '../providers.dart';
import 'bookings_outbox_dispatcher.dart';

enum SyncStatus { synced, pending, error }

/// Backoff schedule expressed as a single `attempt -> delay` function.
/// Attempts are 1-indexed; the first failure schedules the second
/// attempt at +2s, the next at +4s, and so on, capped at 300s.
Duration defaultBackoff(int attempt) {
  // Cap the exponent so `pow` does not overflow into infinity for
  // pathologically large attempts (defensive — the worker stops
  // retrying after 5 anyway).
  final exponent = attempt.clamp(1, 30);
  final seconds = math.min(300, math.pow(2, exponent).toInt());
  return Duration(seconds: seconds);
}

/// Maximum number of automatic retries before the row is flagged as
/// requiring manual user intervention.
const int kMaxAutoRetries = 5;

class OutboxWorker {
  OutboxWorker({
    required this.db,
    required BookingsOutboxDispatcher dispatcher,
    Duration Function(int attempt) backoff = defaultBackoff,
    Future<void> Function(Duration) sleep = _defaultSleep,
  }) : _dispatcher = dispatcher,
       _backoff = backoff,
       _sleep = sleep;

  final AppDatabase db;
  final BookingsOutboxDispatcher _dispatcher;
  final Duration Function(int attempt) _backoff;
  final Future<void> Function(Duration) _sleep;

  StreamSubscription<dynamic>? _connectivitySub;
  StreamSubscription<dynamic>? _outboxSub;
  bool _draining = false;
  bool _online = false;

  void start(Stream<bool> connectivity) {
    _connectivitySub?.cancel();
    _connectivitySub = connectivity.listen((online) {
      _online = online;
      if (online) {
        _scheduleDrain();
      }
    });
    _outboxSub?.cancel();
    _outboxSub = db.outboxDao.watchPending().listen((rows) {
      if (rows.isEmpty) return;
      AppLogger.i('outbox', 'pending=${rows.length}');
      if (_online) _scheduleDrain();
    });
  }

  /// Manually triggers a drain. Exposed so the UI can wire a
  /// "retry now" affordance without having to flip connectivity.
  Future<void> drainNow() async {
    if (!_online) return;
    await _scheduleDrain();
  }

  Future<void> _scheduleDrain() async {
    if (_draining) return;
    _draining = true;
    try {
      await _drainLoop();
    } finally {
      _draining = false;
    }
  }

  Future<void> _drainLoop() async {
    // Loop until the queue is empty OR every remaining row has its
    // `nextAttemptAt` in the future. We deliberately re-read pending
    // rows each iteration so newly enqueued items are picked up
    // without spinning up a fresh drain.
    while (_online) {
      final pending = await db.outboxDao.watchPending().first;
      if (pending.isEmpty) return;

      final now = DateTime.now();
      final ready = pending
          .where(
            (r) => r.nextAttemptAt == null || !r.nextAttemptAt!.isAfter(now),
          )
          .toList(growable: false);
      if (ready.isEmpty) {
        // Sleep until the soonest scheduled attempt, then re-check.
        final soonest = pending
            .where((r) => r.nextAttemptAt != null)
            .map((r) => r.nextAttemptAt!)
            .fold<DateTime?>(null, (acc, t) {
              return acc == null || t.isBefore(acc) ? t : acc;
            });
        if (soonest == null) return;
        final wait = soonest.difference(now);
        if (wait.inMilliseconds > 0) await _sleep(wait);
        continue;
      }

      for (final row in ready) {
        if (!_online) return;
        await _dispatchOne(row);
      }
    }
  }

  Future<void> _dispatchOne(OutboxRow row) async {
    final result = await _dispatcher.drain(row);
    switch (result.outcome) {
      case DispatchOutcome.success:
      case DispatchOutcome.statusConflictResolved:
        await db.outboxDao.deleteItem(row.id);
        break;
      case DispatchOutcome.retry:
        final attempts = row.attempts + 1;
        if (attempts >= kMaxAutoRetries) {
          await db.outboxDao.markManualRetry(
            row.id,
            lastError:
                result.error ??
                'Auto-retry limit reached after $attempts attempts.',
          );
        } else {
          final delay = _backoff(attempts);
          await db.outboxDao.markAttempt(
            row.id,
            attempts: attempts,
            nextAttemptAt: DateTime.now().add(delay),
            lastError: result.error,
          );
        }
        break;
      case DispatchOutcome.manualRetry:
        await db.outboxDao.markManualRetry(
          row.id,
          lastError: result.error ?? 'Permanent failure (4xx).',
        );
        break;
    }
  }

  void stop() {
    _connectivitySub?.cancel();
    _outboxSub?.cancel();
  }
}

Future<void> _defaultSleep(Duration d) => Future<void>.delayed(d);

/// Sync status derived from the outbox state. The dashboard sync indicator
/// reads this provider and renders one of three colored dots.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  await for (final rows in db.outboxDao.watchAll()) {
    if (rows.isEmpty) {
      yield SyncStatus.synced;
    } else if (rows.any((r) => r.status == 'manual_retry')) {
      yield SyncStatus.error;
    } else {
      yield SyncStatus.pending;
    }
  }
});

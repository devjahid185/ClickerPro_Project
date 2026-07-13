// lib/core/crash/crash_bootstrap.dart
//
// One place that installs global error handlers and forwards every uncaught
// error to CrashService, which POSTs it to /api/crash-reports. Both entry
// points (studio `main.dart` and PRO ADMIN `main_admin.dart`) call
// [runGuarded] so a crash on any surface — mobile or Flutter web — reaches the
// admin console. Landing-page (plain HTML) errors are handled separately with
// a small window.onerror script.
//
// The handlers are best-effort: reporting must never itself crash the app, so
// every send is wrapped and swallowed inside CrashService.recordError.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/crash_reporting/data/crash_service.dart';

/// Runs [appBuilder] inside a guarded zone with all three Flutter error hooks
/// wired to [CrashService]. [container] is the same ProviderScope container the
/// app is mounted with, so the crash service shares the authenticated
/// ApiClient and user context.
///
/// Pass the built widget tree via [appBuilder] (not a prebuilt widget) so it's
/// constructed inside the guarded zone.
void runGuarded({
  required ProviderContainer container,
  required Widget Function() appBuilder,
}) {
  final crash = container.read(crashServiceProvider);

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      // Framework-level build/layout/paint errors. Still show the red screen
      // in debug (presentError) but always report.
      final previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        previous?.call(details);
        crash.recordError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      };

      // Errors that escape the framework (e.g. from platform callbacks).
      // Returning true marks them handled so the engine doesn't also crash.
      PlatformDispatcher.instance.onError = (error, stack) {
        crash.recordError(error, stack);
        return true;
      };

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: appBuilder(),
        ),
      );
    },
    // Uncaught async errors that never hit the Flutter hooks land here.
    (error, stack) => crash.recordError(error, stack),
  );
}

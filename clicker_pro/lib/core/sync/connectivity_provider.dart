import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits `true` when the device is online (any non-`none` connectivity result),
/// `false` otherwise. Defaults to `true` on first emission to avoid showing
/// the offline banner before the first probe completes.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final c = Connectivity();
  yield true;
  final initial = await c.checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);
  yield* c.onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
});

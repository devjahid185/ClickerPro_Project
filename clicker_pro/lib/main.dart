import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web: use clean path URLs (no `#`) so shared deep links like
  // `/book/<token>` resolve to the right screen. No-op on mobile.
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Load .env BEFORE the first frame — it's a fast local file read and
  // AppConfig needs it synchronously. A missing/malformed file must never
  // crash startup; AppConfig falls back to safe defaults when a key is absent.
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env not bundled or unreadable; continue with defaults.
  }

  // Paint the UI immediately, then initialize Firebase in the background.
  // Blocking `runApp` on Firebase's network-bound init was the main cause of
  // the long white native-launch flash and the "slow to open" feel. Nothing
  // on the first screen (splash) needs Firebase, so let it warm up after the
  // first frame instead.
  runApp(const ProviderScope(child: ClickerProApp()));

  Firebase.initializeApp(options: DefaultFirebaseOptions.android)
      .catchError((Object e) {
    debugPrint('Firebase initialization error: $e');
    return Firebase.app();
  });
}

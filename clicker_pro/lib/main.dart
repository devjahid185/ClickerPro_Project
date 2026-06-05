import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env, but never let a missing/malformed file crash startup —
  // AppConfig falls back to safe defaults when a key is absent.
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env not bundled or unreadable; continue with defaults.
  }

  runApp(const ProviderScope(child: ClickerProApp()));
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Load .env, but never let a missing/malformed file crash startup —
  // AppConfig falls back to safe defaults when a key is absent.
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env not bundled or unreadable; continue with defaults.
  }

  runApp(const ProviderScope(child: ClickerProApp()));
}

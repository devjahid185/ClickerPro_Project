// lib/features/settings/application/language_controller.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageController extends AsyncNotifier<String> {
  // English-only app: language is fixed to 'en'. (The Bengali path was
  // removed — the picker no longer offers another option.)
  @override
  Future<String> build() async => 'en';

  Future<void> setLanguage(String code) async {
    // No-op: the app is English-only.
    state = const AsyncData('en');
  }
}

final languageControllerProvider =
    AsyncNotifierProvider<LanguageController, String>(LanguageController.new);

/// Convenience: synchronous Locale view for MaterialApp.locale. Always English.
final activeLocaleProvider = Provider<Locale>((ref) => const Locale('en'));

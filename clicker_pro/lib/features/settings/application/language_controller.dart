// lib/features/settings/application/language_controller.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class LanguageController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    return ref.read(preferencesRepositoryProvider).getLanguage();
  }

  Future<void> setLanguage(String code) async {
    state = const AsyncLoading();
    await ref.read(preferencesRepositoryProvider).setLanguage(code);
    state = AsyncData(code);
  }
}

final languageControllerProvider =
    AsyncNotifierProvider<LanguageController, String>(LanguageController.new);

/// Convenience: synchronous Locale view for MaterialApp.locale.
final activeLocaleProvider = Provider<Locale>((ref) {
  final code = ref
      .watch(languageControllerProvider)
      .maybeWhen(data: (c) => c, orElse: () => 'en');
  return Locale(code);
});

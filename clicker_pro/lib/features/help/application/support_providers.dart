// lib/features/help/application/support_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/support_api.dart';
import '../data/support_repository_impl.dart';
import '../domain/faq_entry.dart';
import '../domain/support_repository.dart';

final supportApiProvider = Provider<SupportApi>(
  (ref) => SupportApi(ref.read(apiClientProvider)),
);

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepositoryImpl(api: ref.read(supportApiProvider)),
);

final faqsProvider = FutureProvider<List<FaqEntry>>(
  (ref) => ref.read(supportRepositoryProvider).faqs(),
);

/// Admin-configurable Help & Support contact channels. Defaults to the
/// bundled email and no WhatsApp; the backend value (admin Settings page)
/// overrides both. Kept as a tolerant future so a backend hiccup never hides
/// the Help screen — [supportContactProvider] falls back to the default.
const supportContactFallback = (
  email: 'support@graphy7.app',
  whatsapp: '',
);

final supportContactProvider =
    FutureProvider<({String email, String whatsapp})>((ref) async {
  try {
    final cfg = await ref.read(supportApiProvider).config();
    return (
      email: cfg.email.isNotEmpty ? cfg.email : supportContactFallback.email,
      whatsapp: cfg.whatsapp,
    );
  } catch (_) {
    return supportContactFallback;
  }
});

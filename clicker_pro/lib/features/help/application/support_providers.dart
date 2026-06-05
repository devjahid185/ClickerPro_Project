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

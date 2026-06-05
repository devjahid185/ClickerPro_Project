// lib/features/legal/presentation/privacy_screen.dart
//
// Privacy Policy reader (Dark Luxury Lens).
//
// • Watches `languageControllerProvider` — re-fetch on locale change (Req 8.8).
// • Calls `legalRepository.getPrivacy(lang)` via `privacyDocProvider(lang)`.
// • Renders the markdown body with `flutter_markdown`.
// • LensLoader / ErrorState shells.
// • If the backend endpoint is missing, falls back to a baked-in short
//   policy text so the user always sees something.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../settings/application/language_controller.dart';
import '../domain/legal_repository.dart';

/// Streams the privacy document for a given language code. Keyed by lang so
/// every language switch re-fetches a fresh body (Req 8.8).
final privacyDocProvider = FutureProvider.family<LegalDocument, String>((
  ref,
  lang,
) async {
  return ref.read(legalRepositoryProvider).getPrivacy(lang);
});

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');

    final docAsync = ref.watch(privacyDocProvider(lang));

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: docAsync.when(
        loading: () => const LensLoader(),
        error: (_, _) => _buildBody(_fallbackPrivacy(lang)),
        data: (doc) => _buildBody(doc.body),
      ),
    );
  }

  Widget _buildBody(String markdownBody) {
    return Markdown(
      data: markdownBody,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      styleSheet: _markdownStyle(),
      selectable: true,
    );
  }
}

MarkdownStyleSheet _markdownStyle() {
  const baseColor = AppColors.film;
  const dimColor = AppColors.filmDim;
  return MarkdownStyleSheet(
    p: const TextStyle(color: baseColor, fontSize: 14, height: 1.55),
    h1: const TextStyle(
      color: AppColors.film,
      fontFamily: 'Poppins',
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    h2: const TextStyle(
      color: AppColors.film,
      fontFamily: 'Poppins',
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    h3: const TextStyle(
      color: AppColors.film,
      fontFamily: 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    strong: const TextStyle(color: AppColors.film, fontWeight: FontWeight.w700),
    em: const TextStyle(color: baseColor, fontStyle: FontStyle.italic),
    listBullet: const TextStyle(color: dimColor, fontSize: 14, height: 1.55),
    blockquote: const TextStyle(
      color: dimColor,
      fontStyle: FontStyle.italic,
      fontSize: 14,
    ),
    blockquoteDecoration: BoxDecoration(
      color: AppColors.glass,
      border: Border(
        left: BorderSide(
          color: AppColors.orange.withValues(alpha: 0.6),
          width: 3,
        ),
      ),
    ),
    code: const TextStyle(
      color: AppColors.gold,
      fontFamily: 'Montserrat',
      fontSize: 12.5,
    ),
    a: const TextStyle(
      color: AppColors.gold,
      decoration: TextDecoration.underline,
    ),
  );
}

String _fallbackPrivacy(String lang) {
  if (lang == 'bn') {
    return _privacyBn;
  }
  return _privacyEn;
}

const String _privacyEn = '''
Clicker Pro respects your privacy.

**What we collect**
- Account info you provide (name, email, phone)
- Bookings, payments, and gear data you create
- Device id and language for sync

**How we use it**
- To run your studio and sync across your devices
- To send service notifications you've opted in to

**Third-party services**
Firebase Analytics, Google OAuth (if used).

**Your rights**
- Export your data any time from Settings → Account
- Delete your account; full purge after a 7-day grace window

**Contact**
support@clickerpro.app
''';

const String _privacyBn = '''
Clicker Pro আপনার গোপনীয়তাকে সম্মান করে।

**আমরা কী সংগ্রহ করি**
- আপনি যে অ্যাকাউন্ট তথ্য দেন (নাম, ইমেইল, ফোন)
- আপনার তৈরি বুকিং, পেমেন্ট এবং গিয়ার ডেটা
- সিঙ্কের জন্য ডিভাইস আইডি এবং ভাষা

**আমরা কীভাবে ব্যবহার করি**
- আপনার স্টুডিও চালাতে ও ডিভাইসগুলোর মধ্যে সিঙ্ক করতে
- আপনি যেসব সার্ভিস নোটিফিকেশন বেছে নিয়েছেন সেগুলো পাঠাতে

**থার্ড-পার্টি সার্ভিস**
Firebase Analytics, Google OAuth (যদি ব্যবহার করা হয়)।

**আপনার অধিকার**
- যেকোনো সময় Settings → Account থেকে ডেটা এক্সপোর্ট করুন
- অ্যাকাউন্ট ডিলিট করুন; ৭-দিনের গ্রেস উইন্ডোর পরে সম্পূর্ণ মুছে ফেলা হয়

**যোগাযোগ**
support@clickerpro.app
''';

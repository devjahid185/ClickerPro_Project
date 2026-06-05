// lib/features/legal/presentation/terms_screen.dart
//
// Terms of Service reader (Dark Luxury Lens). Mirror of PrivacyScreen.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../settings/application/language_controller.dart';
import '../domain/legal_repository.dart';

final termsDocProvider = FutureProvider.family<LegalDocument, String>((
  ref,
  lang,
) async {
  return ref.read(legalRepositoryProvider).getTerms(lang);
});

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');

    final docAsync = ref.watch(termsDocProvider(lang));

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
          'Terms of Service',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: docAsync.when(
        loading: () => const LensLoader(),
        error: (_, _) => _buildBody(_fallbackTerms(lang)),
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
    a: const TextStyle(
      color: AppColors.gold,
      decoration: TextDecoration.underline,
    ),
  );
}

String _fallbackTerms(String lang) {
  if (lang == 'bn') return _termsBn;
  return _termsEn;
}

const String _termsEn = '''
By using Clicker Pro you agree to:

**Account responsibility**
Keep your credentials secure. You are responsible for your team and your data.

**Acceptable use**
No unlawful activity. Respect client privacy and copyright.

**Termination**
We may suspend accounts that violate these terms.

**Liability**
Provided as-is. No warranty for outages or data loss beyond reasonable backups.

**Governing law**
Laws of Bangladesh apply.

**Contact**
support@clickerpro.app
''';

const String _termsBn = '''
Clicker Pro ব্যবহার করে আপনি সম্মত হচ্ছেন:

**অ্যাকাউন্টের দায়িত্ব**
আপনার ক্রেডেনশিয়াল সুরক্ষিত রাখুন। আপনার টিম ও ডেটার জন্য আপনি দায়ী।

**গ্রহণযোগ্য ব্যবহার**
কোনো বেআইনি কার্যকলাপ নয়। ক্লায়েন্টের গোপনীয়তা ও কপিরাইটকে সম্মান করুন।

**অ্যাকাউন্ট বন্ধ**
এই শর্ত লঙ্ঘনকারী অ্যাকাউন্ট আমরা স্থগিত করতে পারি।

**দায়বদ্ধতা**
যেমন আছে তেমনই দেওয়া হয়েছে। যৌক্তিক ব্যাকআপের বাইরে আউটেজ বা ডেটা লসের জন্য কোনো ওয়ারেন্টি নেই।

**প্রযোজ্য আইন**
বাংলাদেশের আইন প্রযোজ্য হবে।

**যোগাযোগ**
support@clickerpro.app
''';

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
import '../../../theme/app_theme.dart';

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
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Terms of Service',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
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
  final baseColor = AppColors.film;
  final dimColor = AppColors.filmDim;
  return MarkdownStyleSheet(
    p: TextStyle(color: baseColor, fontSize: 14, height: 1.55),
    h1: TextStyle(
      color: AppColors.film,
      fontFamily: AppText.brandFontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    h2: TextStyle(
      color: AppColors.film,
      fontFamily: AppText.brandFontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    h3: TextStyle(
      color: AppColors.film,
      fontFamily: AppText.brandFontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    strong: TextStyle(color: AppColors.film, fontWeight: FontWeight.w700),
    em: TextStyle(color: baseColor, fontStyle: FontStyle.italic),
    listBullet: TextStyle(color: dimColor, fontSize: 14, height: 1.55),
    a: TextStyle(
      color: AppColors.gold,
      decoration: TextDecoration.underline,
    ),
  );
}

String _fallbackTerms(String lang) => _termsEn;

const String _termsEn = '''
By using Graphy7 you agree to:

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
support@graphy7.app
''';


import 'package:flutter/material.dart';

import '../../../core/di/locator.dart';
import '../../../core/network/api_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../l10n/l10n.dart';
import 'profile_ui.dart';

/// Yasal metin anahtarları (`GET /app/legal/{key}`); gövde panelden gelir.
enum LegalDoc { terms, privacy, kvkk, consent, health }

extension LegalDocX on LegalDoc {
  // TODO(varsayım): Anahtar adları backend ile netleşmeli (kvkk mock'u mevcut; diğerleri `app.legal._.json`).
  String get key => switch (this) {
    LegalDoc.terms => 'terms',
    LegalDoc.privacy => 'privacy',
    LegalDoc.kvkk => 'kvkk',
    LegalDoc.consent => 'consent',
    LegalDoc.health => 'health',
  };

  String title(AppLocalizations l) => switch (this) {
    LegalDoc.terms => l.profileLegalTerms,
    LegalDoc.privacy => l.profileLegalPrivacy,
    LegalDoc.kvkk => l.profileLegalKvkk,
    LegalDoc.consent => l.profileLegalConsent,
    LegalDoc.health => l.profileLegalHealth,
  };
}

/// "YASAL METİNLER" kartı: 52 px satırlar, sağda chevron; dokununca metin sheet'te açılır.
class LegalLinksCard extends StatelessWidget {
  const LegalLinksCard({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return DividedCard(
      radius: AppRadii.tile,
      margin: margin,
      lineColor: p.sf2,
      children: [
        for (final doc in LegalDoc.values)
          InkWell(
            onTap: () => showLegalSheet(context, doc),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        doc.title(l),
                        style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink),
                      ),
                    ),
                    AppIcon(AppIcons.chevronRight, size: 16, color: p.mut, strokeWidth: 2.4),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Metni `AppRepository.legalText` ile getirip alt sayfada gösterir.
Future<void> showLegalSheet(BuildContext context, LegalDoc doc) {
  final title = doc.title(context.l10n);
  final future = sl<AppRepository>().legalText(doc.key);
  return AppSheet.show<void>(
    context,
    builder: (ctx) => _LegalBody(title: title, future: future),
  );
}

class _LegalBody extends StatelessWidget {
  const _LegalBody({required this.title, required this.future});

  final String title;
  final Future<ApiResult<String>> future;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTypography.display(24, color: p.ink)),
        ),
        const SizedBox(height: 12),
        FutureBuilder<ApiResult<String>>(
          future: future,
          builder: (context, snap) => switch (snap.data) {
            null => const Shimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 180, height: 14),
                ],
              ),
            ),
            Success(:final data) => Text(
              data,
              style: AppTypography.body(15, weight: FontWeight.w600, color: p.ink, height: 1.5),
            ),
            Failure(:final error) => InlineAlert(errorMessageOf(context, error)),
          },
        ),
        const SizedBox(height: 20),
        AppButton(
          label: context.l10n.commonClose,
          variant: AppButtonVariant.outlineInk,
          size: AppButtonSize.medium,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

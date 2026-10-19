import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/auth/auth_requests.dart';
import '../../../l10n/l10n.dart';
import '../view_model/register_view_model.dart';
import 'big_field.dart';
import 'legal_sheet.dart';
import 'login_form.dart' show issueText;
import 'register_steps.dart';

String legalTitle(BuildContext context, LegalDoc d) {
  final l = context.l10n;
  return switch (d) {
    LegalDoc.terms => l.authLegalTerms,
    LegalDoc.privacy => l.authLegalPrivacy,
    LegalDoc.kvkk => l.authLegalKvkk,
    LegalDoc.health => l.authLegalHealth,
    LegalDoc.explicitConsent => l.authLegalExplicit,
  };
}

Future<void> _read(BuildContext context, RegisterViewModel vm, LegalDoc d) async {
  final ok = await LegalSheet.show(context, title: legalTitle(context, d), load: () => vm.legalText(d));
  if (ok) {
    Haptics.selection();
    vm.acceptConsent(d);
  }
}

/// 4 · Teleferik — 4 zorunlu sözleşme + ayrı, isteğe bağlı Açık Rıza (KVKK).
class AgreementsStep extends StatelessWidget {
  const AgreementsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<RegisterViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepTitle(l.authRegLegalTitle),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(24), boxShadow: p.cardShadow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in LegalDoc.required)
                Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
                  child: Row(
                    children: [
                      Expanded(
                        child: MergeSemantics(
                          child: InkWell(
                            onTap: () {
                              Haptics.selection();
                              vm.toggleConsent(d);
                            },
                            child: Row(
                              children: [
                                Checkbox(value: vm.isAccepted(d), onChanged: (_) => vm.toggleConsent(d), activeColor: p.teal),
                                Expanded(child: Text(legalTitle(context, d), style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _ReadButton(doc: d, onTap: () => _read(context, vm, d)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                child: Text(l.authLegalAllRequired, style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ExplicitConsent(vm: vm),
      ],
    );
  }
}

class _ReadButton extends StatelessWidget {
  const _ReadButton({required this.doc, required this.onTap});

  final LegalDoc doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: context.l10n.authLegalReadSemantics(legalTitle(context, doc)),
      excludeSemantics: true,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 40),
          backgroundColor: p.sf2,
          foregroundColor: p.teal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(context.l10n.authLegalRead, style: AppTypography.body(13, weight: FontWeight.w900, color: p.teal)),
      ),
    );
  }
}

/// Açık Rıza: kesik çerçeveli ayrı kutu + anahtar (diğer onaylardan bağımsız).
class _ExplicitConsent extends StatelessWidget {
  const _ExplicitConsent({required this.vm});

  final RegisterViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return CustomPaint(
      painter: _DashedRRect(p.borderStrong),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '${l.authExplicitTitle} ',
                      style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
                      children: [TextSpan(text: l.authExplicitOptional, style: AppTypography.body(15, weight: FontWeight.w800, color: p.mut))],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(l.authExplicitBody, style: AppTypography.body(12, color: p.mut)),
                  _ReadButton(doc: LegalDoc.explicitConsent, onTap: () => _read(context, vm, LegalDoc.explicitConsent)),
                ],
              ),
            ),
            Switch(
              value: vm.explicitConsent,
              activeTrackColor: p.teal,
              onChanged: (v) {
                Haptics.selection();
                vm.setExplicitConsent(value: v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  _DashedRRect(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect o) => o.color != color;
}

/// 18 yaş altı: 16–17 → veli onay bağlantısı; daha küçük → misafir.
class UnderAgeStep extends StatelessWidget {
  const UnderAgeStep({super.key, required this.onGuest});

  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<RegisterViewModel>();
    final parent = vm.underAge == UnderAgeKind.needsParent;
    final face = '<svg viewBox="0 0 120 120"><path d="M30 14 Q18 8 18 22 V98 Q18 112 30 106 L104 68 Q114 60 104 52 Z" fill="${p.coinMark.hex}"/>'
        '<ellipse cx="44" cy="54" rx="6" ry="8" fill="${p.onTile.hex}"/><ellipse cx="62" cy="56" rx="6" ry="8" fill="${p.onTile.hex}"/>'
        '<path d="M44 72 Q53 66 62 72" stroke="${p.onTile.hex}" stroke-width="4" fill="none" stroke-linecap="round"/></svg>';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: SvgArt(face, width: 96, height: 96)),
        const SizedBox(height: 16),
        StepTitle(parent ? l.authUnderAgeTitle : l.authTooYoungTitle, size: 34),
        const SizedBox(height: 16),
        StepNote(
          parent
              ? l.authUnderAgeBody(RegisterViewModel.minAge, RegisterViewModel.adultAge - 1, Fmt.number(vm.onboardingBonus))
              : l.authTooYoungBody(RegisterViewModel.minAge),
        ),
        if (parent) ...[
          const SizedBox(height: 16),
          if (vm.parentSent)
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: p.successSoft, borderRadius: BorderRadius.circular(16)),
                child: Text(l.authParentSent, style: AppTypography.body(14, weight: FontWeight.w800, color: p.successText)),
              ),
            )
          else
            BigField(
              label: l.authParentPhone,
              hint: l.authPhoneHint,
              keyboardType: TextInputType.phone,
              inputFormatters: const [PhoneGroupFormatter(leadingZero: true)],
              error: vm.showIssues && vm.parentPhoneIssue != null ? issueText(context, vm.parentPhoneIssue!) : null,
              onChanged: vm.setParentPhone,
            ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onGuest,
            style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: EdgeInsets.zero),
            child: Text(
              l.authGuestContinue,
              style: AppTypography.body(15, weight: FontWeight.w900, color: p.teal).copyWith(decoration: TextDecoration.underline, decorationColor: p.teal),
            ),
          ),
        ),
      ],
    );
  }
}

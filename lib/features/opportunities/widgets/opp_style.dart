import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../l10n/l10n.dart';

/// Fırsat kartlarında ortak görsel kurallar (ton, vurgu, stok metni).
extension OppTone on AppPalette {
  /// API `tone` 1–6 → pastel karo.
  Color tone(int t) => tiles[(t - 1).clamp(0, 5)];

  /// Görsel alanındaki vurgu dairesi (tasarımdaki `acc`).
  Color toneAccent(int t) => switch (t) {
    1 => hotFill,
    2 => secondary,
    3 => primary,
    4 => buanFill,
    5 => secondary,
    _ => cta,
  };
}

extension OppTexts on AppLocalizations {
  String claimTypeLabel(ClaimType t) => switch (t) {
    ClaimType.code => oppTypeCode,
    ClaimType.qr => oppTypeQr,
    ClaimType.pnr => oppTypePnr,
  };

  // TODO(varsayım): stok %50'nin altındaysa "Son N kod", üstündeyse "Bol" (tasarım örneklerinden).
  String stockLabel(Opportunity o) => o.stockRatio < .5 ? oppStockLast(o.stockRemaining) : oppStockPlenty;

  String filterLabel(OpportunityFilter f) => switch (f) {
    OpportunityFilter.nearby => oppFilterNearby,
    OpportunityFilter.newest => oppFilterNew,
    OpportunityFilter.ending => oppFilterEnding,
    OpportunityFilter.favorites => oppFilterFavorites,
  };

  /// "12 Ekim’de" — Türkçe bulunma eki ay adına göre (ARB `select`).
  String dateLoc(DateTime d) => oppDateLoc(d.day, 'm${d.month}');
}

/// Görsel alanındaki logo karosu (48 / 64 px). Logo URL'si yoksa kısaltma yazılır.
class OppLogoTile extends StatelessWidget {
  const OppLogoTile({super.key, required this.text, this.size = 48, this.radius = 16, this.fontSize = 12, this.shadow = true});

  final String text;
  final double size, radius, fontSize;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.line),
        boxShadow: shadow ? [BoxShadow(color: p.onTile.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        style: AppTypography.body(fontSize, weight: FontWeight.w900, color: p.onTile),
      ),
    );
  }
}

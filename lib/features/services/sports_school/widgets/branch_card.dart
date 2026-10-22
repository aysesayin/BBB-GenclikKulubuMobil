import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../view_model/sports_school_view_model.dart';

/// Branş kartı: 56 px pastel karo + ad + kontenjan ("12 yer", "Son 3", "DOLU").
class BranchCard extends StatelessWidget {
  const BranchCard({super.key, required this.tile, required this.onTap});

  final BranchTile tile;
  final VoidCallback? onTap;

  /// Kontenjan metni ve rengi ("12 yer" / "Son 3" / "DOLU"); Kolay Mod satırları da kullanır.
  static (String, Color) quotaOf(BuildContext context, BranchTile tile) {
    final p = context.palette;
    final l = context.l10n;
    final left = tile.offer?.left ?? 0;
    return switch (tile.level) {
      QuotaLevel.none => (l.svcQuotaNone, p.mut),
      QuotaLevel.full => (l.svcQuotaFull, p.pinkT),
      QuotaLevel.last => (l.svcQuotaLast('$left'), p.pinkT),
      QuotaLevel.plenty => (l.svcQuotaLeft('$left'), p.grnT),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final (quota, color) = quotaOf(context, tile);
    return Semantics(
      button: true,
      enabled: onTap != null,
      excludeSemantics: true,
      label: l.svcBranchSemantics(tile.branch.name, quota),
      child: Opacity(
        opacity: onTap == null ? .6 : 1,
        child: Material(
          color: p.sf,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTile(icon: SvcIcons.of(tile.branch.icon), color: SvcFmt.tile(p, tile.branch.tile), size: 56, radius: 18, iconSize: 28),
                  const SizedBox(height: 8),
                  Text(
                    tile.branch.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(13, weight: FontWeight.w900, color: p.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(quota, style: AppTypography.body(11, weight: FontWeight.w800, color: color)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

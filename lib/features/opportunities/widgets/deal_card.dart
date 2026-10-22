import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../l10n/l10n.dart';
import 'opp_style.dart';

/// C1 fırsat kartı: 1050×360 görsel alanı (indirim rozeti sol üst, favori kalbi sağ üst,
/// tip rozeti sağ alt), logo karosu, "12 gün kaldı · Son 40 kod" tek satır + ince stok çubuğu.
/// Kolay Mod: başlık 18 px.
class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.deal, required this.now, required this.onTap, required this.onFavorite});

  final Opportunity deal;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final easy = context.easyMode;
    final days = deal.daysLeft(now);
    final urgent = deal.isEndingSoon(now);
    final stock = l.stockLabel(deal);
    final meta = l.oppMetaLine(l.daysLeft(days), stock);
    return Stack(
      children: [
        AppCard(
          radius: AppRadii.card,
          padding: EdgeInsets.zero,
          clip: true,
          onTap: onTap,
          semanticLabel: l.oppCardSemantics(deal.brand, deal.title, deal.discountLabel, l.daysLeft(days), stock),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DealImage(deal: deal),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -38),
                        child: OppLogoTile(text: deal.logoText),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deal.locationLabel.isEmpty ? deal.brand : '${deal.brand} · ${deal.locationLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              deal.title,
                              style: AppTypography.body(easy ? 18 : 16, weight: FontWeight.w800, height: 1.25, color: p.ink),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                AppIcon(AppIcons.clock, size: 14, color: urgent ? p.pinkT : p.mut, strokeWidth: 2.4),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    meta,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body(easy ? 14 : 12, weight: FontWeight.w800, color: urgent ? p.pinkT : p.mut),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AppProgressBar(
                              value: deal.stockRatio,
                              color: deal.isLowStock ? p.hotFill : p.primary,
                              semanticsValue: stock,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: FavoriteButton(active: deal.isFavorite, onTap: onFavorite, background: p.paper),
        ),
      ],
    );
  }
}

/// Kartın 1050×360 görsel alanı (görsel yoksa ton + blob illüstrasyonu).
class DealImage extends StatelessWidget {
  const DealImage({super.key, required this.deal});

  final Opportunity deal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final art = SvgArt(
      '<svg viewBox="0 0 353 121" preserveAspectRatio="xMidYMid slice">'
      '<path d="M210 -20c70 0 150 30 145 90s-70 70-130 62-80-40-72-85 0-67 57-67z" fill="${p.paper.hex}" fill-opacity=".35"/>'
      '<circle cx="70" cy="100" r="46" fill="${p.toneAccent(deal.tone).hex}" fill-opacity=".45"/></svg>',
      fit: BoxFit.cover,
    );
    return AspectRatio(
      aspectRatio: 1050 / 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: p.tone(deal.tone)),
          if (deal.imageUrl case final url?) CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, _, _) => art) else art,
          Positioned(left: 14, top: 14, child: TagBadge(label: deal.discountLabel, fontSize: 15, radius: 12)),
          Positioned(
            right: 14,
            bottom: 12,
            child: TagBadge(
              label: context.l10n.claimTypeLabel(deal.claimType),
              fontSize: 11,
              background: p.paper.withValues(alpha: .88),
              foreground: p.onTile,
            ),
          ),
        ],
      ),
    );
  }
}

/// 44 px kalp butonu; dolu → sıcak pembe. [background] → beyaz daire (görsel üstünde).
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.active, required this.onTap, this.background, this.activeColor});

  final bool active;
  final VoidCallback onTap;
  final Color? background, activeColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = active ? (activeColor ?? p.hotFill) : (activeColor ?? p.mut);
    return Semantics(
      button: true,
      toggled: active,
      label: active ? context.l10n.oppFavoriteRemove : context.l10n.oppFavoriteAdd,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          radius: 22,
          onTap: () {
            Haptics.selection();
            onTap();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              boxShadow: background == null ? null : [BoxShadow(color: p.onTile.withValues(alpha: .15), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: AppIcon(AppIcons.heart, key: ValueKey(active), size: 22, color: c, fill: active ? c : null, strokeWidth: 2.2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Liste skeleton'ı (S1).
class DealCardSkeleton extends StatelessWidget {
  const DealCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    radius: AppRadii.card,
    padding: EdgeInsets.zero,
    clip: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AspectRatio(aspectRatio: 1050 / 360, child: SkeletonBox(radius: 0)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(
            children: [
              const SkeletonBox(width: 48, height: 48, radius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 120, height: 12),
                    const SizedBox(height: 8),
                    SkeletonBox(width: MediaQuery.sizeOf(context).width * .5, height: 16),
                    const SizedBox(height: 10),
                    const SkeletonBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

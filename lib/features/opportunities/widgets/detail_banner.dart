import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'deal_card.dart';
import 'opp_icons.dart';
import 'opp_style.dart';

/// C2 banner'ı (1400×800 → yükseklik = genişlik / 1,75) + geri / paylaş / favori butonları.
class DetailBanner extends StatelessWidget {
  const DetailBanner({
    super.key,
    required this.tone,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
    this.imageUrl,
  });

  final int tone;
  final String? imageUrl;
  final bool isFavorite;
  final VoidCallback onFavorite, onShare;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final glass = p.paper.withValues(alpha: .92);
    final art = SvgArt(_art(p), fit: BoxFit.cover);
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        height: (c.maxWidth / 1.75).roundToDouble(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: p.tone(tone)),
            if (imageUrl case final url?) CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, _, _) => art) else art,
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  AppIconButton(
                    icon: AppIcons.back,
                    semanticLabel: l.commonBack,
                    background: glass,
                    color: p.onTile,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  AppIconButton(
                    icon: OppIcons.share,
                    semanticLabel: l.commonShare,
                    background: glass,
                    color: p.onTile,
                    iconSize: 20,
                    onPressed: onShare,
                  ),
                  const SizedBox(width: 8),
                  FavoriteButton(active: isFavorite, onTap: onFavorite, background: glass, activeColor: p.pinkT),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tasarımdaki tırmanma duvarı illüstrasyonu (renkler palette'ten).
  String _art(AppPalette p) {
    String dot(int x, int y, Color c) => '<circle cx="$x" cy="$y" r="7" fill="${c.hex}"/>';
    return '<svg viewBox="0 0 393 225" preserveAspectRatio="xMidYMid slice">'
        '<path d="M240 -30c90 0 170 50 160 140s-80 120-160 110-110-60-100-130 20-120 100-120z" fill="${p.hotFill.hex}" fill-opacity=".55"/>'
        '<rect x="70" y="40" width="120" height="190" rx="10" fill="${p.buanFill.hex}" fill-opacity=".85"/>'
        '${dot(95, 70, p.cta)}${dot(140, 95, p.coinMark)}${dot(110, 130, p.secondary)}'
        '${dot(160, 150, p.cta)}${dot(100, 180, p.coinMark)}${dot(150, 205, p.hotFill)}'
        '<path d="M300 180 Q320 120 290 80" stroke="${p.onTile.hex}" stroke-width="3" fill="none"/></svg>';
  }
}

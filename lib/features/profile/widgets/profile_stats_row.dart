import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/profile/profile_stats.dart';
import '../../../l10n/l10n.dart';
import 'profile_icons.dart';

/// Sayaç ızgarası: toplam BUAN (mor), etkinlik (turkuaz), fırsat (pembe) ve ilçe sırası (yeşil,
/// dokununca lig tablosu). Sıra 0 ise karo gizlenir.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.stats, this.onRank});

  final ProfileStats stats;
  final VoidCallback? onRank;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final rank = stats.districtRank;
    final items = [
      _StatTile(value: stats.totalBuanEarned, label: l.profileStatBuan, color: p.purT),
      _StatTile(value: stats.eventsAttended, label: l.profileStatEvents, color: p.teal),
      _StatTile(value: stats.opportunitiesUsed, label: l.profileStatOpportunities, color: p.pinkT),
      if (rank > 0)
        _StatTile(
          value: rank,
          valueText: l.profileStatRankValue(rank),
          label: l.profileStatDistrictRank,
          color: p.grnT,
          semanticLabel: l.profileStatRankSemantics(rank),
          onTap: onRank,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: items[i])],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.color, this.valueText, this.semanticLabel, this.onTap});

  final int value;
  final String label;
  final Color color;

  /// Verilirse sayaç animasyonu yerine düz metin ("14.").
  final String? valueText;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = AppTypography.number(22, color: color);
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.tile)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: valueText != null ? Text(valueText!, style: style) : CountUpText(value: value, style: style),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.body(11, weight: FontWeight.w800, color: p.mut, height: 1.2),
          ),
        ],
      ),
    );
    if (onTap == null) return MergeSemantics(child: tile);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadii.tile), child: tile),
      ),
    );
  }
}

/// "Rozet vitrinim" kartı: eğik sticker rozetler + "7 rozet" bağlantısı.
class BadgeShowcase extends StatelessWidget {
  const BadgeShowcase({super.key, required this.stats, required this.onOpen});

  final ProfileStats stats;
  final VoidCallback onOpen;

  static const _tilt = [-5.0, 3.0, -2.0, 4.0];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l.profileBadgesTitle, style: AppTypography.display(18, color: p.ink)),
                ),
              ),
              TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  foregroundColor: p.teal,
                ),
                child: Text(
                  l.profileBadgeCount(stats.badgeCount),
                  style: AppTypography.body(14, weight: FontWeight.w900, color: p.teal),
                ),
              ),
            ],
          ),
          if (stats.featuredBadges.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                for (var i = 0; i < stats.featuredBadges.length; i++)
                  _BadgeSticker(badge: stats.featuredBadges[i], tilt: _tilt[i % _tilt.length], onTap: onOpen),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeSticker extends StatelessWidget {
  const _BadgeSticker({required this.badge, required this.tilt, required this.onTap});

  final FeaturedBadge badge;
  final double tilt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tone = p.tiles[(badge.tone - 1).clamp(0, 5)];
    return Semantics(
      button: true,
      label: badge.name,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: tilt * math.pi / 180,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(AppRadii.tile),
              border: Border.all(color: p.onTile, width: 3),
              boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(3, 3))],
            ),
            alignment: Alignment.center,
            child: AppIcon(ProfileIcons.badge(badge.icon), size: 30, color: p.onTile, strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

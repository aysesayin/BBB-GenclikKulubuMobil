import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_league.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_icons.dart';
import '../view_model/league_view_model.dart';

/// İlk üç: 2 · 1 · 3 sıralı podyum.
class LeaguePodium extends StatelessWidget {
  const LeaguePodium({super.key, required this.top});

  final List<BuanLeagueEntry> top;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ring = [p.cta, p.tile3, p.tile6];
    final avatar = [p.tile6, p.tile2, p.tile1];
    final order = [1, 0, 2].where((i) => i < top.length).toList();
    return Semantics(
      container: true,
      label: context.l10n.buanLeaguePodium,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var k = 0; k < order.length; k++) ...[
            if (k > 0) const SizedBox(width: 10),
            Expanded(
              child: _Step(
                entry: top[order[k]],
                first: order[k] == 0,
                height: const [96.0, 70.0, 52.0][order[k]],
                ring: ring[order[k]],
                avatar: avatar[order[k]],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.entry, required this.first, required this.height, required this.ring, required this.avatar});

  final BuanLeagueEntry entry;
  final bool first;
  final double height;
  final Color ring, avatar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = first ? 76.0 : 62.0;
    final pts = Fmt.number(entry.points);
    return Semantics(
      label: context.l10n.buanLeagueRowSemantics(entry.rank, entry.name, pts),
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: avatar,
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(entry.initials, style: AppTypography.display(20, color: p.onTile)),
          ),
          const SizedBox(height: 6),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(14, weight: FontWeight.w900, color: p.ink),
          ),
          const SizedBox(height: 6),
          Text(
            pts,
            style: AppTypography.number(12, weight: FontWeight.w800, color: p.purT),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            padding: const EdgeInsets.only(top: 8),
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              color: ring,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text('${entry.rank}', style: AppTypography.display(28, color: p.onTile)),
          ),
        ],
      ),
    );
  }
}

/// Bölge ayırıcısı: çizgi · ok · etiket · çizgi.
class LeagueZoneHeader extends StatelessWidget {
  const LeagueZoneHeader({super.key, required this.zone});

  final LeagueZone zone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final (String label, Color c, String icon) = switch (zone) {
      LeagueZone.promotion => (l.buanLeagueZoneUp, p.grnT, BuanIcons.arrowUp),
      LeagueZone.safe => (l.buanLeagueZoneSafe, p.mut, BuanIcons.flat),
      LeagueZone.relegation => (l.buanLeagueZoneDown, p.pinkT, BuanIcons.arrowDown),
    };
    Widget line() => Expanded(child: Container(height: 2, color: c.withValues(alpha: .5)));
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            line(),
            const SizedBox(width: 8),
            AppIcon(icon, size: 14, color: c, strokeWidth: 3),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.body(12, weight: FontWeight.w900, color: c),
            ),
            const SizedBox(width: 8),
            line(),
          ],
        ),
      ),
    );
  }
}

/// Liste satırı (4. sıradan itibaren).
class LeagueRow extends StatelessWidget {
  const LeagueRow({super.key, required this.entry});

  final BuanLeagueEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final av = [p.tile6, p.tile2, p.tile1, p.tile3, p.tile4, p.tile5][entry.rank % 6];
    final name = entry.isMe ? l.buanLeagueMeName(entry.name) : entry.name;
    final pts = Fmt.number(entry.points);
    return Semantics(
      label: l.buanLeagueRowSemantics(entry.rank, name, pts),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: entry.isMe ? p.purS : Colors.transparent, borderRadius: BorderRadius.circular(AppRadii.md)),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text('${entry.rank}', style: AppTypography.number(15, color: p.mut)),
            ),
            const SizedBox(width: 12),
            _Avatar(initials: entry.initials, color: av),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink),
              ),
            ),
            const SizedBox(width: 8),
            Text(pts, style: AppTypography.number(14, color: p.purT)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: AppTypography.body(13, weight: FontWeight.w900, color: context.palette.onTile),
    ),
  );
}

/// Alt navigasyonun üstünde yapışkan "Sen" satırı.
class LeagueMeBar extends StatelessWidget {
  const LeagueMeBar({super.key, required this.me, this.subtitle});

  final BuanLeagueEntry me;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final pts = Fmt.number(me.points);
    return Semantics(
      container: true,
      label: [l.buanLeagueRowSemantics(me.rank, l.buanLeagueMe, pts), ?subtitle].join('. '),
      excludeSemantics: true,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: p.buanFill,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: p.buanShadow.withValues(alpha: .4), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text('${me.rank}', style: AppTypography.number(15, color: p.onBuan)),
            ),
            const SizedBox(width: 12),
            _Avatar(initials: me.initials, color: p.yelS),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.buanLeagueMe,
                    style: AppTypography.body(15, weight: FontWeight.w900, color: p.onBuan),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(11, weight: FontWeight.w800, color: p.onBuan.withValues(alpha: .9)),
                    ),
                ],
              ),
            ),
            Text(pts, style: AppTypography.number(15, color: p.glow)),
          ],
        ),
      ),
    );
  }
}

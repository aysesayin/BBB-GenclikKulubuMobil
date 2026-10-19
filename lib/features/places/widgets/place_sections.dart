import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/places/place.dart';
import '../../../l10n/l10n.dart';
import '../../map/widgets/map_icons.dart';

/// "Burada yapabileceklerin" satırı: renkli zemin + 44 px ikon karosu + başlık + BUAN rozeti / ok.
class PlaceActionRow extends StatelessWidget {
  const PlaceActionRow({super.key, required this.action, required this.onTap});

  final PlaceAction action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color bg, Color tile, Color onTileColor, String icon) = switch (action.type) {
      PlaceActionType.checkin => (p.purS, p.buanFill, p.onBuan, MapIcons.qr),
      PlaceActionType.opportunity => (p.pinkS, p.hotFill, p.onHot, MapIcons.tag),
      PlaceActionType.event => (p.tealS, p.primary, p.onTile, MapIcons.calendar),
      PlaceActionType.task || PlaceActionType.unknown => (p.yelS, p.cta, p.onCta, AppIcons.sparkle),
    };
    final buan = action.buan;
    return Semantics(
      button: onTap != null,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: AppIcon(icon, size: 22, color: onTileColor),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(action.title, style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink))),
                const SizedBox(width: 8),
                if (buan != null && buan > 0)
                  BuanPointsBadge(points: buan, minWidth: 60, height: 28)
                else
                  AppIcon(AppIcons.chevronRight, size: 18, color: p.ink, strokeWidth: 2.4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bölüm başlığı (Baloo 20) + içerik.
class PlaceSection extends StatelessWidget {
  const PlaceSection({super.key, required this.title, required this.child, this.gap = 8});

  final String title;
  final Widget child;
  final double gap;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: AppTypography.display(20, color: context.palette.ink))),
          SizedBox(height: gap),
          child,
        ],
      );
}

/// Çalışma saatleri tablosu (gün · saat / "Kapalı").
class PlaceHoursTable extends StatelessWidget {
  const PlaceHoursTable({super.key, required this.hours});

  final List<PlaceHours> hours;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Column(
      children: [
        for (var i = 0; i < hours.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
            child: Row(
              children: [
                Expanded(child: Text(hours[i].days, style: AppTypography.body(14, color: p.mut))),
                const SizedBox(width: 12),
                Text(
                  hours[i].closed || hours[i].hours == null ? l.placeClosed : hours[i].hours!,
                  style: AppTypography.number(14, color: hours[i].closed ? p.pinkT : p.ink),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Olanak çipleri (34 px, zemin rengi).
class PlaceAmenities extends StatelessWidget {
  const PlaceAmenities({super.key, required this.amenities});

  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in amenities)
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(17)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Text(a, style: AppTypography.body(13, weight: FontWeight.w800, color: p.ink))]),
          ),
      ],
    );
  }
}

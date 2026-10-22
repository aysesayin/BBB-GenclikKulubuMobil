import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/map/map_pin.dart';
import '../../../l10n/l10n.dart';
import '../../events/widgets/discover_palette.dart';
import '../../places/utils/directions.dart';
import 'map_icons.dart';

/// Alt navigasyonun üstündeki yatay şerit: en yakın 3 yer (ad, mesafe, kategori).
/// Dokununca harita o pine ortalanır ve önizleme açılır.
class NearestStrip extends StatelessWidget {
  const NearestStrip({super.key, required this.items, required this.categoryLabelOf, required this.distanceOf, required this.onTap});

  final List<MapPin> items;
  final String Function(MapPin) categoryLabelOf;
  final int Function(MapPin) distanceOf;
  final ValueChanged<MapPin> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox(width: double.infinity);
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Semantics(
            header: true,
            child: Text(context.l10n.mapNearestTitle, style: AppTypography.body(12, weight: FontWeight.w900, color: p.mut)),
          ),
        ),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _NearestCard(
              pin: items[i],
              category: categoryLabelOf(items[i]),
              distance: formatDistance(context, distanceOf(items[i])),
              onTap: () => onTap(items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _NearestCard extends StatelessWidget {
  const _NearestCard({required this.pin, required this.category, required this.distance, required this.onTap});

  final MapPin pin;
  final String category, distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: context.l10n.mapNearestSemantics(pin.name, category, distance),
      excludeSemantics: true,
      child: Material(
        color: p.sf,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            Haptics.selection();
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 196,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: p.cardShadow),
            child: Row(
              children: [
                IconTile(icon: MapIcons.forKey(pin.icon), color: paletteColor(p, pin.tone), size: 44, radius: 14, iconSize: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pin.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body(13, weight: FontWeight.w900, color: p.ink)),
                      const SizedBox(height: 2),
                      Text(
                        [distance, category].where((s) => s.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(11, weight: FontWeight.w800, color: p.mut),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

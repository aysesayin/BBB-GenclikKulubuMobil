import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/map/map_pin.dart';
import '../../../l10n/l10n.dart';
import '../../events/widgets/discover_palette.dart';

/// G3 üst katman: geri + "Yakınımdaki yerler" + katman segmenti + kategori çipleri.
class MapTopBar extends StatelessWidget {
  const MapTopBar({
    super.key,
    required this.layer,
    required this.categories,
    required this.categoryId,
    required this.onBack,
    required this.onNearby,
    required this.onLayer,
    required this.onCategory,
    this.showCategories = false,
  });

  final MapLayer layer;
  final List<MapCategory> categories;
  final String? categoryId;
  final VoidCallback onBack, onNearby;
  final ValueChanged<MapLayer> onLayer;
  final ValueChanged<String> onCategory;

  /// Çipler ikinci satır olarak yalnız katman seçildikten sonra görünür (Kolay Mod: hiç).
  final bool showCategories;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final easy = context.easyMode;
    final chips = showCategories && !easy && categories.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AppIconButton(icon: AppIcons.back, semanticLabel: l.commonBack, onPressed: onBack, size: easy ? 56 : 48, background: p.sf, shadow: true),
              const SizedBox(width: 8),
              Expanded(child: _NearbyPill(onTap: onNearby, easy: easy)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _LayerSegment(layer: layer, onChanged: onLayer)),
        if (chips) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _CategoryChip(
                category: categories[i],
                selected: categories[i].id == categoryId,
                onTap: () => onCategory(categories[i].id),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NearbyPill extends StatelessWidget {
  const _NearbyPill({required this.onTap, required this.easy});

  final VoidCallback onTap;

  /// Kolay Mod: 56 px, dolgulu "liste" düğmesi görünümü.
  final bool easy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = easy ? context.l10n.mapEasyNearbyCta : context.l10n.mapNearbyPlaces;
    return Semantics(
      button: true,
      child: Material(
        color: easy ? p.onTile : p.sf,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: easy ? 56 : 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: p.cardShadow),
            child: Row(
              children: [
                AppIcon(easy ? AppIcons.pin : AppIcons.search, size: easy ? 24 : 20, color: easy ? p.paper : p.mut),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: easy ? AppTypography.body(17, weight: FontWeight.w900, color: p.paper) : AppTypography.body(15, color: p.mut),
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

class _LayerSegment extends StatelessWidget {
  const _LayerSegment({required this.layer, required this.onChanged});

  final MapLayer layer;
  final ValueChanged<MapLayer> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final labels = {MapLayer.places: l.mapLayerPlaces, MapLayer.events: l.mapLayerEvents, MapLayer.opportunities: l.mapLayerOpportunities};
    return Semantics(
      label: l.mapLayersLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(18), boxShadow: p.cardShadow),
        child: Row(
          children: [
            for (final entry in labels.entries) ...[
              if (entry.key != MapLayer.places) const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: entry.key == layer,
                  child: GestureDetector(
                    onTap: () {
                      Haptics.selection();
                      onChanged(entry.key);
                    },
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: entry.key == layer ? p.onTile : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(14, weight: FontWeight.w900, color: entry.key == layer ? p.paper : p.ink),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.selected, required this.onTap});

  final MapCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.chip,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? p.onTile : p.sf,
            borderRadius: BorderRadius.circular(19),
            boxShadow: p.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: paletteColor(p, category.color, fallback: p.primary), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(category.label, style: AppTypography.body(13, weight: FontWeight.w900, color: selected ? p.paper : p.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

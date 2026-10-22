import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../l10n/l10n.dart';
import 'easy_pill.dart';
import 'opp_icons.dart';
import 'opp_style.dart';

/// Kategori karoları (kullanım sırasına göre, "Tümü" yok): 72 px sütun, 58 px karo;
/// seçili → sticker (2,5 px ink çerçeve + 3/3 sert gölge). Seçiliye tekrar dokunmak kaldırır.
/// Kolay Mod: yatay kaydırma yerine 56 px çiplerden oluşan dikey sarmal.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({super.key, required this.categories, required this.selected, required this.onSelect});

  final List<OpportunityCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    if (categories.isEmpty) return const SizedBox(height: 16);
    if (context.easyMode) {
      return Semantics(
        label: l.oppCategoriesLabel,
        container: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in categories)
                EasyPill(
                  label: c.id == selected ? l.oppCategorySelected(c.label) : c.label,
                  icon: OppIcons.byKey(c.icon),
                  color: p.tone(c.tone),
                  selected: c.id == selected,
                  onTap: () => onSelect(c.id),
                ),
            ],
          ),
        ),
      );
    }
    return Semantics(
      label: l.oppCategoriesLabel,
      container: true,
      child: SizedBox(
        height: 108,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final c = categories[i];
            final isSelected = c.id == selected;
            return _CategoryTile(
              label: c.label,
              semanticLabel: isSelected ? l.oppCategorySelected(c.label) : c.label,
              icon: OppIcons.byKey(c.icon),
              color: p.tone(c.tone),
              selected: isSelected,
              onTap: () {
                Haptics.selection();
                onSelect(c.id);
              },
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label, semanticLabel, icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              AnimatedContainer(
                duration: AppDurations.chip,
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.tile),
                  border: selected ? Border.all(color: p.onTile, width: 2.5) : null,
                  boxShadow: selected ? [BoxShadow(color: p.onTile, offset: const Offset(3, 3))] : null,
                ),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 24, color: p.onTile, strokeWidth: 2.1),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(12, weight: selected ? FontWeight.w900 : FontWeight.w700, color: p.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filtre çipleri: Yakınımda · Yeni · Bitmek üzere · Favoriler. Kolay Mod: 56 px, sarmal.
class FilterStrip extends StatelessWidget {
  const FilterStrip({super.key, required this.selected, required this.onToggle});

  final OpportunityFilter? selected;
  final ValueChanged<OpportunityFilter> onToggle;

  static const _icons = {
    OpportunityFilter.nearby: AppIcons.pinSimple,
    OpportunityFilter.newest: AppIcons.sparkle,
    OpportunityFilter.ending: AppIcons.clock,
    OpportunityFilter.favorites: AppIcons.heart,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (context.easyMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final f in OpportunityFilter.values)
              EasyPill(label: l.filterLabel(f), icon: _icons[f], selected: selected == f, onTap: () => onToggle(f)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: PillRow(
        children: [
          for (final f in OpportunityFilter.values)
            FilterPill(label: l.filterLabel(f), icon: _icons[f], selected: selected == f, onTap: () => onToggle(f)),
        ],
      ),
    );
  }
}

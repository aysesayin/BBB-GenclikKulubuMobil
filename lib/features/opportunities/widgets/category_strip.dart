import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../l10n/l10n.dart';
import 'opp_icons.dart';
import 'opp_style.dart';

/// Kategori karoları: 72 px sütun, 58 px karo; seçili → sticker (2,5 px ink çerçeve + 3/3 sert gölge).
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({super.key, required this.categories, required this.selected, required this.onSelect});

  final List<OpportunityCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final all = (null, context.l10n.commonAll, AppIcons.grid, p.tile6);
    final entries = [all, for (final c in categories) (c.id, c.label, OppIcons.byKey(c.icon), p.tone(c.tone))];
    return Semantics(
      label: context.l10n.oppCategoriesLabel,
      container: true,
      child: SizedBox(
        height: 108,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final (id, label, icon, color) = entries[i];
            return _CategoryTile(
              label: label,
              icon: icon,
              color: color,
              selected: id == selected,
              onTap: () {
                Haptics.selection();
                onSelect(id);
              },
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  final String label, icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
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

/// Filtre çipleri: Yakınımda · Yeni · Bitmek üzere · Favoriler.
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 6),
    child: PillRow(
      children: [
        for (final f in OpportunityFilter.values)
          FilterPill(label: context.l10n.filterLabel(f), icon: _icons[f], selected: selected == f, onTap: () => onToggle(f)),
      ],
    ),
  );
}

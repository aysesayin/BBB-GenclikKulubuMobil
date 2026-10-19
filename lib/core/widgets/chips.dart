import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import 'app_icon.dart';

/// Filtre çipi (40 px): seçili → ink dolgu, değil → yüzey + 1.5 px çizgi.
class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.bg : p.ink;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          Haptics.light();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.chip,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? p.ink : p.sf,
            borderRadius: BorderRadius.circular(20),
            border: selected ? null : Border.all(color: p.line, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[AppIcon(icon!, size: 16, color: fg, strokeWidth: 2.4), const SizedBox(width: 6)],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body(14, weight: FontWeight.w900, color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yatay kaydırılan çip şeridi (20 px kenar boşluklu).
class PillRow extends StatelessWidget {
  const PillRow({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 20), this.gap = 8});

  final List<Widget> children;
  final EdgeInsets padding;
  final double gap;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(width: gap), children[i]]]),
      );
}

/// Sticker çip: seçiliyken pastel dolgu, 2 px ink çerçeve, sert gölge ve −2° eğim
/// (ilgi alanları, rozet seçimi).
class StickerChip extends StatelessWidget {
  const StickerChip({super.key, required this.label, required this.selected, required this.onTap, this.color, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          Haptics.light();
          onTap();
        },
        child: AnimatedRotation(
          turns: selected ? -2 / 360 : 0,
          duration: AppDurations.chip,
          child: AnimatedContainer(
            duration: AppDurations.chip,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? (color ?? p.mint) : p.sf,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? p.onTile : p.mut, width: 2),
              boxShadow: selected ? [BoxShadow(color: p.onTile, offset: const Offset(3, 3))] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[AppIcon(icon!, size: 18, color: selected ? p.onTile : p.ink), const SizedBox(width: 6)],
                Text(
                  label,
                  style: AppTypography.body(15, weight: selected ? FontWeight.w900 : FontWeight.w800, color: selected ? p.onTile : p.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segment sekmeleri (Kazan / Pazar / Lig): yüzey2 zemin, seçili beyaz kart.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.sf2, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                child: GestureDetector(
                  onTap: () {
                    Haptics.selection();
                    onChanged(i);
                  },
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    height: 40,
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 2, right: i == labels.length - 1 ? 0 : 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? p.sf : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: i == index ? [BoxShadow(color: p.shadowColor, blurRadius: 6, offset: const Offset(0, 2))] : null,
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(14, weight: i == index ? FontWeight.w900 : FontWeight.w800, color: i == index ? p.ink : p.mut),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Küçük etiket rozeti (ör. "%25", "BÜYÜK ÖDÜL", "Popüler").
class TagBadge extends StatelessWidget {
  const TagBadge({super.key, required this.label, this.background, this.foreground, this.fontSize = 13, this.radius = 10});

  final String label;
  final Color? background, foreground;
  final double fontSize, radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize < 12 ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(color: background ?? p.chip, borderRadius: BorderRadius.circular(radius)),
      child: Text(label, maxLines: 1, style: AppTypography.body(fontSize, weight: FontWeight.w900, color: foreground ?? p.onChip)),
    );
  }
}

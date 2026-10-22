import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';

/// Kolay Mod filtre/kategori çipi: 56 px yüksek, 16 px metin, geniş dokunma alanı.
/// (Çekirdek [FilterPill] 40 px sabittir; Kolay Mod'da bu kullanılır.)
class EasyPill extends StatelessWidget {
  const EasyPill({super.key, required this.label, required this.selected, required this.onTap, this.icon, this.color});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;

  /// Kategori tonu (seçiliyken dolgu); null → ink.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fill = selected ? (color ?? p.ink) : p.sf;
    final fg = selected ? (color == null ? p.bg : p.onTile) : p.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.chip,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: selected ? p.onTile : p.line, width: selected ? 2.5 : 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[AppIcon(icon!, size: 22, color: fg, strokeWidth: 2.4), const SizedBox(width: 8)],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body(16, weight: FontWeight.w900, color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// Menü satırı verisi.
class ProfileMenuItem {
  const ProfileMenuItem({
    required this.label,
    required this.icon,
    required this.tile,
    required this.onTap,
    this.badge,
    this.iconColor,
    this.foreground,
    this.chevron = true,
  });

  final String label, icon;
  final Color tile;
  final VoidCallback onTap;

  /// Sağdaki pembe hap ("1 ödeme bekliyor").
  final String? badge;
  final Color? iconColor, foreground;
  final bool chevron;
}

/// "Hesap menüsü" kartı: 58 px satırlar, 36 px ikon karosu, chevron.
/// [large] (Kolay Mod): 64 px satır, 18 px etiket, 44 px ikon karosu.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.label,
    required this.items,
    this.margin = const EdgeInsets.fromLTRB(20, 16, 20, 28),
    this.large = false,
  });

  final String label;
  final List<ProfileMenuItem> items;
  final EdgeInsetsGeometry margin;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Padding(
        padding: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: ColoredBox(
            color: p.sf,
            child: Column(
              children: [for (var i = 0; i < items.length; i++) _Row(item: items[i], divider: i < items.length - 1, large: large)],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.divider, required this.large});

  final ProfileMenuItem item;
  final bool divider, large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = item.foreground ?? p.ink;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: item.onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: large ? 64 : 58),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: divider ? Border(bottom: BorderSide(color: p.line)) : null,
          ),
          child: Row(
            children: [
              Container(
                width: large ? 44 : 36,
                height: large ? 44 : 36,
                decoration: BoxDecoration(color: item.tile, borderRadius: BorderRadius.circular(AppRadii.sm)),
                alignment: Alignment.center,
                child: AppIcon(item.icon, size: large ? 24 : 20, color: item.iconColor ?? p.onTile, strokeWidth: 2.2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    item.label,
                    style: AppTypography.body(large ? 18 : 15, weight: FontWeight.w800, color: fg),
                  ),
                ),
              ),
              if (item.badge != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.pinkS, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      item.badge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(12, weight: FontWeight.w900, color: p.pinkT),
                    ),
                  ),
                ),
              ],
              if (item.chevron) ...[const SizedBox(width: 14), AppIcon(AppIcons.chevronRight, size: 18, color: p.mut, strokeWidth: 2.4)],
            ],
          ),
        ),
      ),
    );
  }
}

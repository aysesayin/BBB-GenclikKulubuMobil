import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/widgets/widgets.dart';

/// Hizmet satırı (havuz hizmeti, tenis ürünü): 48 px pastel ikon karosu + başlık + sağ içerik.
/// Kolay Mod: 64 px karo ve daha büyük başlık.
class ServiceRowCard extends StatelessWidget {
  const ServiceRowCard({
    super.key,
    required this.icon,
    required this.tileColor,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tags = const [],
    this.trailing,
    this.semanticLabel,
  });

  final String icon;
  final Color tileColor;
  final String title;
  final String? subtitle;
  final List<String> tags;
  final Widget? trailing;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final easy = context.easyMode;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: p.sf,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconTile(icon: icon, color: tileColor, size: easy ? 64 : 48, radius: easy ? 20 : 16, iconSize: easy ? 30 : 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.body(easy ? 17 : 15, weight: FontWeight.w900, color: p.ink)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppTypography.body(12, color: p.mut)),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(spacing: 6, runSpacing: 6, children: [for (final t in tags) _Tag(t)]),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: p.sf2, borderRadius: BorderRadius.circular(11)),
      child: Center(widthFactor: 1, child: Text(label, style: AppTypography.body(11, weight: FontWeight.w900, color: p.ink))),
    );
  }
}

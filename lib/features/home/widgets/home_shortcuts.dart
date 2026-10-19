import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_items.dart';
import '../../../l10n/l10n.dart';
import '../home_links.dart';
import 'home_icons.dart';

/// 4 sütunlu kısayol ızgarası (satır arası 14, sütun arası 8).
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key, required this.items});

  final List<HomeShortcut> items;

  static const columns = 4;

  @override
  Widget build(BuildContext context) {
    final rows = <List<HomeShortcut>>[
      for (var i = 0; i < items.length; i += columns) items.sublist(i, (i + columns).clamp(0, items.length)),
    ];
    return Semantics(
      container: true,
      label: context.l10n.homeShortcutsSemantics,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Column(
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: 8),
                    Expanded(child: c < rows[r].length ? _ShortcutItem(item: rows[r][c]) : const SizedBox.shrink()),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  const _ShortcutItem({required this.item});

  final HomeShortcut item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        onTap: () => openLink(context, item.link),
        child: Column(
          children: [
            IconTile(icon: HomeIcons.of(item.icon), color: toneColor(p, item.tone)),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(12, weight: FontWeight.w800, color: p.ink, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

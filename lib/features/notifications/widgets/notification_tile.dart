import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/notifications/app_notification.dart';
import '../../../l10n/l10n.dart';
import '../../home/home_links.dart';
import '../../home/widgets/home_icons.dart';

/// Bildirim satırı: ikon karosu + başlık + açıklama + "zaman · kategori".
/// Okunmamış → sarımsı zemin + nokta + "Yeni" metni (yalnız renk değil). Kolay Mod: satır ≥ 56 px.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item, required this.meta, required this.onTap});

  final AppNotification item;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final semantics = [if (item.unread) l.commonUnread, item.title, item.body, meta].where((s) => s.isNotEmpty).join(', ');
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: item.unread ? p.yelS : p.sf,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: context.easyMode ? 56 : 0),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(icon: HomeIcons.of(item.icon), color: toneColor(p, item.tone), size: 44, radius: 14, iconSize: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink, height: 1.3),
                      ),
                      if (item.body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.body,
                          style: AppTypography.body(13, weight: FontWeight.w600, color: p.mut, height: 1.35),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
                      ),
                    ],
                  ),
                ),
                if (item.unread) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: p.hotFill, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.notifNew,
                        style: AppTypography.body(11, weight: FontWeight.w900, color: p.pinkT),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bildirim listesi yükleniyor.
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      children: [
        const SkeletonBox(width: 64, height: 13, radius: 6),
        for (var i = 0; i < 6; i++) ...[const SizedBox(height: 8), const SkeletonBox(height: 92, radius: 20)],
      ],
    ),
  );
}

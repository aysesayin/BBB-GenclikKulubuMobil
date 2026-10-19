import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/watch_video.dart';
import '../../../../../l10n/l10n.dart';
import '../../widgets/task_dates.dart';

/// "SIRADAKİ VİDEOLAR" — kilitli videolar ve açılma zamanı.
class UpNextList extends StatelessWidget {
  const UpNextList({super.key, required this.items});

  final List<UpcomingVideo> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final tiles = [p.tile1, p.tile2, p.tile3];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              trUpper(l.taskWatchUpNext),
              style: AppTypography.body(13, weight: FontWeight.w900, color: p.mut).copyWith(letterSpacing: .5),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 44,
                    decoration: BoxDecoration(color: tiles[i % tiles.length], borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: AppIcon(AppIcons.lock, size: 20, color: p.onTile, strokeWidth: 2.4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[i].title,
                      style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink),
                    ),
                  ),
                  if (items[i].availableAt case final at?) ...[
                    const SizedBox(width: 8),
                    Text(
                      l.taskWatchAvailableIn(daysUntil(at)),
                      style: AppTypography.body(12, weight: FontWeight.w900, color: p.mut),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

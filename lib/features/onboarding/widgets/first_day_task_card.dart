import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/auth/first_day_task.dart';
import '../../../l10n/l10n.dart';

/// "İlk günün" satırı: pastel ikon karosu + başlık/alt yazı + BUAN rozeti.
/// Tamamlanınca karo yeşil tik olur, metin solar, rozet "Tamamlandı" der.
class FirstDayTaskCard extends StatelessWidget {
  const FirstDayTaskCard({super.key, required this.task, required this.done, required this.onTap});

  final FirstDayTask task;
  final bool done;
  final VoidCallback onTap;

  /// API'deki ikon anahtarı → tasarım ikonu.
  static String iconOf(String key) => switch (key) {
        'tag' => AppIcons.tag,
        'qr' => AppIcons.qr,
        'gift' => AppIcons.gift,
        'bell' => AppIcons.bell,
        'steps' => AppIcons.steps,
        'calendar' => AppIcons.calendar,
        _ => AppIcons.sparkle,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final easy = context.easyMode;
    final tile = switch (task.icon) {
      'tag' => p.tile2,
      'qr' => p.tile4,
      'gift' => p.tile1,
      _ => p.tile3,
    };
    final amount = Fmt.signed(task.reward);
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(14, easy ? 16 : 12, 14, easy ? 16 : 12),
      semanticLabel: done ? l.onbFirstDayDoneSemantics(task.title) : l.onbFirstDayTaskSemantics(task.title, amount),
      child: ExcludeSemantics(
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              width: easy ? 60 : 54,
              height: easy ? 60 : 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: done ? p.successSoft : tile, borderRadius: BorderRadius.circular(AppRadii.tile)),
              child: AppIcon(
                done ? AppIcons.check : iconOf(task.icon),
                size: 26,
                color: done ? p.successText : p.onTile,
                strokeWidth: done ? 3 : 2,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(easy ? 17 : 16, weight: FontWeight.w900, height: 1.2, color: done ? p.mut : p.ink).copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: p.mut,
                    ),
                  ),
                  if (task.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(task.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.body(13, height: 1.3, color: p.mut)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (done)
              BuanPointsBadge.text(l.onbFirstDayDone, background: p.successSoft, foreground: p.successText, fontSize: 12)
            else
              BuanPointsBadge(points: task.reward, height: 28, fontSize: 14),
          ],
        ),
      ),
    );
  }
}

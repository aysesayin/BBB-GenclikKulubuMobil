import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/buan/buan_task.dart';
import '../../../l10n/l10n.dart';
import 'buan_icons.dart';
import 'buan_ui.dart';
import 'task_card.dart';

/// Uygulama içi akışı olmayan / kilitli / tamamlanmış görevler için kurallar sheet'i.
abstract final class TaskInfoSheet {
  static Future<void> show(BuildContext context, BuanTask task) => AppSheet.show<void>(
    context,
    builder: (ctx) => _Body(task: task, outer: context),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.task, required this.outer});

  final BuanTask task;

  /// Sheet kök navigator'da açılır; sekme içi yönlendirme dış bağlamla yapılır.
  final BuildContext outer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final status = switch (task.status) {
      BuanTaskStatus.locked => l.buanEarnSheetLocked(buanTaskLockLabel(l, task)),
      BuanTaskStatus.done => l.buanEarnSheetDone,
      // TODO(varsayım): Bu görevlerin (Takip Et, Gönül Dostu, BİKO, Fikrin ile Kazan, Fırsat Kullan)
      // uygulama içi akışı tasarlanmadı; panel/harici süreçle tamamlanıyor varsayıldı.
      _ => l.buanEarnSheetSoon,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconTile(icon: BuanIcons.task(task.type), color: buanTile(p, task.tile), size: 52, radius: 18, iconSize: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(task.title, style: AppTypography.display(24, color: p.ink)),
              ),
            ),
            const SizedBox(width: 8),
            TaskPointsBadge(task: task),
          ],
        ),
        if (task.subtitle.isNotEmpty) ...[const SizedBox(height: 10), Text(task.subtitle, style: AppTypography.body(14, color: p.mut))],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: task.isLocked ? p.sf2 : p.tealS, borderRadius: BorderRadius.circular(AppRadii.md)),
          child: Row(
            children: [
              AppIcon(task.isLocked ? AppIcons.lock : AppIcons.info, size: 20, color: task.isLocked ? p.mut : p.teal, strokeWidth: 2.4),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink),
                ),
              ),
            ],
          ),
        ),
        if (task.frequency != null) ...[
          const SizedBox(height: 12),
          Text(
            l.buanEarnSheetFrequency(task.frequency!),
            style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink),
          ),
        ],
        if (task.rules.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(l.buanEarnSheetRules, style: AppTypography.display(20, color: p.ink)),
          ),
          const SizedBox(height: 8),
          for (final r in task.rules) BuanBullet(text: r),
        ],
        const SizedBox(height: 20),
        if (task.type == BuanTaskType.useOpportunity && !task.isLocked) ...[
          AppButton(
            label: l.buanEarnSheetOpportunities,
            onPressed: () {
              Navigator.of(context).pop();
              GoRouter.of(outer).go(Routes.opportunities);
            },
          ),
          const SizedBox(height: 8),
        ],
        AppButton(
          label: l.buanEarnSheetOk,
          variant: AppButtonVariant.outlineInk,
          size: AppButtonSize.medium,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan/buan_task.dart';
import '../../../../../l10n/l10n.dart';
import '../../../widgets/buan_icons.dart';
import '../../../widgets/buan_ui.dart';
import '../../../widgets/task_card.dart';

/// Başlık kartı: 64 px karo + başlık + alt metin, sağda puan rozeti.
class TaskDetailHeader extends StatelessWidget {
  const TaskDetailHeader({super.key, required this.task});

  final BuanTask task;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: IconTile(icon: BuanIcons.task(task.type), color: buanTile(p, task.tile), size: 64, radius: 20, iconSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(task.title, style: AppTypography.display(22, color: p.ink)),
                ),
                if (task.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(task.subtitle, style: AppTypography.body(13, color: p.mut)),
                ],
                const SizedBox(height: 10),
                TaskPointsBadge(task: task),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Durum kutusu: yapılabilir (ipucu) / panel onayı bekleniyor / tamamlandı / kilitli nedeni.
class TaskStatusBox extends StatelessWidget {
  const TaskStatusBox({super.key, required this.task, this.hint});

  final BuanTask task;

  /// Yapılabilir durumda eylem ipucu ("Resmî hesapları takip ettikten sonra…").
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final (String text, String? sub, String icon, Color bg, Color fg) = switch (task.status) {
      BuanTaskStatus.locked => (l.buanEarnSheetLocked(buanTaskLockLabel(l, task)), null, AppIcons.lock, p.sf2, p.mut),
      BuanTaskStatus.pending => (l.buanTaskPendingState, l.buanTaskPendingHint, AppIcons.clock, p.yelS, p.warningText),
      BuanTaskStatus.done => (l.buanEarnSheetDone, null, AppIcons.check, p.grnS, p.grnT),
      BuanTaskStatus.available => (hint ?? l.buanEarnStatusAvailable, null, AppIcons.info, p.tealS, p.teal),
    };
    return Semantics(
      container: true,
      label: '${l.buanTaskDetailStatusLabel}: $text${sub == null ? '' : '. $sub'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 20, color: fg, strokeWidth: 2.4),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink)),
                  if (sub != null) ...[
                    const SizedBox(height: 4),
                    Text(sub, style: AppTypography.body(12, color: p.mut)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sıklık: 12 haftada 1" satırı.
class TaskFrequencyLine extends StatelessWidget {
  const TaskFrequencyLine({super.key, required this.frequency});

  final String frequency;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        AppIcon(AppIcons.refresh, size: 16, color: p.mut, strokeWidth: 2.4),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.buanEarnSheetFrequency(frequency),
            style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink),
          ),
        ),
      ],
    );
  }
}

/// Başlıklı bölüm (Nasıl yapılır? / Kurallar).
class TaskSection extends StatelessWidget {
  const TaskSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: AppTypography.display(20, color: context.palette.ink)),
      ),
      const SizedBox(height: 10),
      ...children,
    ],
  );
}

/// Numaralı adım satırı.
class TaskStepRow extends StatelessWidget {
  const TaskStepRow({super.key, required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: p.purS, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$index', style: AppTypography.number(13, color: p.purT)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: AppTypography.body(14, weight: FontWeight.w600, height: 1.4, color: p.ink)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Madde işaretli kural satırı.
class TaskRuleRow extends StatelessWidget {
  const TaskRuleRow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => BuanBullet(text: text);
}

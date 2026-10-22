import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/buan/buan_task.dart';
import '../../../l10n/l10n.dart';
import 'buan_icons.dart';
import 'buan_ui.dart';

/// Kilit nedeni metni: sunucu metni > sıklık limiti ("74 gün sonra") > yaş sınırı.
String buanTaskLockLabel(AppLocalizations l, BuanTask t, {DateTime? now}) {
  if (t.lockLabel case final s? when s.isNotEmpty) return s;
  final at = t.availableAt;
  if (t.lock == BuanTaskLock.limit && at != null) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final days = DateUtils.dateOnly(at.toLocal()).difference(today).inDays;
    if (days >= 0) return l.buanEarnAvailableIn(days);
  }
  if (t.lock == BuanTaskLock.age) {
    if (t.minAge != null) return l.buanEarnAgeMin(t.minAge!);
    if (t.maxAge != null) return l.buanEarnAgeMax(t.maxAge!);
  }
  return l.buanEarnStatusLocked;
}

/// Görev kartı: 52 px karo · başlık · alt metin; altında durum rozeti + puan rozeti satırı;
/// ilerleme çubuğu kendi satırında. 360 px'te hiçbir şey kırılmaz / kesilmez.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});

  final BuanTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final easy = context.easyMode;
    final (String label, String icon, Color bg, Color fg) = switch (task.status) {
      BuanTaskStatus.available => (l.buanEarnStatusAvailable, BuanIcons.arrowRight, p.tealS, p.teal),
      BuanTaskStatus.pending => (l.buanEarnStatusPending, AppIcons.clock, p.yelS, p.warningText),
      BuanTaskStatus.done => (l.buanEarnStatusDone, AppIcons.check, p.grnS, p.grnT),
      BuanTaskStatus.locked => (buanTaskLockLabel(l, task), AppIcons.lock, p.sf2, p.mut),
    };
    final dim = task.isDone || task.isLocked;
    final showProgress = task.progress != null && !dim;
    return Opacity(
      opacity: dim ? .75 : 1,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        semanticLabel: l.buanEarnCardSemantics(task.title, task.subtitle, label),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: easy ? 72 : 0),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(icon: BuanIcons.task(task.type), color: buanTile(p, task.tile), size: 52, radius: 18, iconSize: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: AppTypography.body(easy ? 17 : 15, weight: FontWeight.w900, height: 1.2, color: p.ink),
                          ),
                          if (task.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.subtitle,
                              maxLines: easy ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(easy ? 14 : 12, color: p.mut),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Flexible(child: _StatusPill(label: label, icon: icon, bg: bg, fg: fg)),
                              const SizedBox(width: 8),
                              TaskPointsBadge(task: task),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (showProgress) ...[
                  const SizedBox(height: 10),
                  AppProgressBar(value: task.progress!, color: p.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Durum rozeti: dar ekranda uzun kilit metni sığmazsa küçülür, asla satır kırmaz.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.icon, required this.bg, required this.fg});

  final String label, icon;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 12, color: fg, strokeWidth: 3),
          const SizedBox(width: 4),
          Text(label, maxLines: 1, softWrap: false, style: AppTypography.body(11, weight: FontWeight.w900, color: fg)),
        ],
      ),
    ),
  );
}

/// Sabit genişlikli puan rozeti. Aralıklı ödülde ("+10–200") aynı görünümle metin rozeti.
class TaskPointsBadge extends StatelessWidget {
  const TaskPointsBadge({super.key, required this.task});

  final BuanTask task;

  static const _minWidth = 76.0, _height = 30.0;

  @override
  Widget build(BuildContext context) {
    final max = task.pointsMax;
    if (max == null || max <= task.points) {
      return BuanPointsBadge(points: task.points, minWidth: _minWidth, height: _height);
    }
    final p = context.palette;
    final l = context.l10n;
    final min = Fmt.number(task.points), top = Fmt.number(max);
    // TODO(varsayım): BuanPointsBadge yalnız tek değer alıyor; aralık için aynı ölçülerde yerel rozet.
    return Semantics(
      label: l.buanEarnRangeSemantics(min, top),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: _minWidth),
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: p.purS, borderRadius: BorderRadius.circular(_height / 2)),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(l.buanEarnRange(min, top), maxLines: 1, softWrap: false, style: AppTypography.number(13, color: p.purT)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_items.dart';
import '../../../l10n/l10n.dart';
import '../home_links.dart';
import 'home_icons.dart';

/// "Bugünün Görevleri": 158 px kartlar, ilerleme halkası + sabit genişlikli puan rozeti.
class HomeTasks extends StatelessWidget {
  const HomeTasks({super.key, required this.tasks});

  final List<HomeTask> tasks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.l10n.homeTasksTitle, onAction: () => context.go(Routes.buan)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tasks.length; i++) ...[if (i > 0) const SizedBox(width: 12), _TaskCard(task: tasks[i])],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final HomeTask task;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = switch (task.accent) {
      'green' => p.grnT,
      'pink' => p.pinkT,
      'purple' => p.purT,
      'yellow' => p.accentText,
      _ => p.teal,
    };
    return SizedBox(
      width: 158,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => openLink(context, task.link),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ProgressRing(
                  value: task.progress,
                  color: accent,
                  child: AppIcon(HomeIcons.of(task.icon), size: 20, color: accent),
                ),
                const SizedBox(width: 6),
                Flexible(child: BuanPointsBadge(points: task.points)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink, height: 1.2),
            ),
            const SizedBox(height: 10),
            Text(task.subtitle, style: AppTypography.body(12, color: p.mut)),
          ],
        ),
      ),
    );
  }
}

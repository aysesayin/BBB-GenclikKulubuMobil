import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_feed.dart';
import '../../../data/models/home/home_items.dart';
import '../../../l10n/l10n.dart';
import '../home_links.dart';
import '../view_model/home_view_model.dart';
import 'home_deals.dart';
import 'home_events.dart';
import 'home_header.dart';
import 'home_icons.dart';
import 'home_nearby_league.dart';
import 'home_shortcuts.dart';

/// Kolay Mod Keşfet: büyük selam · arama · 4 büyük kısayol kartı · görevler (dikey, en çok 3)
/// · "Daha fazla" altında kalan bloklar. Hikâye, banner karuseli ve harita gösterilmez.
class HomeEasyContent extends StatefulWidget {
  const HomeEasyContent({super.key, required this.feed, required this.greeting, required this.offline, required this.onRefresh});

  final HomeFeed feed;
  final HomeGreeting greeting;
  final bool offline;
  final Future<void> Function() onRefresh;

  /// Kolay Modda gösterilen en fazla görev sayısı.
  static const maxTasks = 3;

  /// Kolay Modda gizlenen bloklar (hikâye, karusel, harita); görevler ayrıca üstte çizilir.
  static const hidden = {HomeBlock.stories, HomeBlock.banners, HomeBlock.nearby, HomeBlock.tasks};

  @override
  State<HomeEasyContent> createState() => _HomeEasyContentState();
}

class _HomeEasyContentState extends State<HomeEasyContent> {
  bool _expanded = false;

  Widget _block(HomeBlock b) => switch (b) {
    HomeBlock.shortcuts => HomeShortcuts(items: widget.feed.shortcuts),
    HomeBlock.deals => HomeDeals(deals: widget.feed.deals),
    HomeBlock.events => HomeEvents(events: widget.feed.events),
    HomeBlock.league => HomeLeagueCard(league: widget.feed.league!),
    _ => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final l = context.l10n;
    final feed = widget.feed;
    final rest = HomeViewModel.blocksOf(feed).where((b) => !HomeEasyContent.hidden.contains(b)).toList();
    final tasks = feed.tasks.take(HomeEasyContent.maxTasks).toList();
    return ColoredBox(
      color: context.palette.bg,
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: context.palette.teal,
        edgeOffset: pad.top,
        child: ListView(
          padding: EdgeInsets.only(bottom: AppSpacing.tabBarHeight + pad.bottom + 16),
          children: [
            if (widget.offline) OfflineBanner(margin: EdgeInsets.fromLTRB(16, pad.top + 8, 16, 0)),
            HomeHeader(feed: feed, greeting: widget.greeting, topInset: widget.offline ? 12 : null, large: true),
            const HomeSearchField(),
            const HomeEasyShortcuts(),
            if (tasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: SectionHeader(title: l.homeTasksTitle, onAction: () => context.go(Routes.buan)),
              ),
              for (final t in tasks)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: HomeEasyTaskRow(task: t),
                ),
            ],
            if (rest.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: AppButton.outline(
                  label: _expanded ? l.homeEasyLess : l.homeEasyMore,
                  size: AppButtonSize.large,
                  trailingIcon: _expanded ? null : AppIcons.chevronDown,
                  onPressed: () {
                    Haptics.selection();
                    setState(() => _expanded = !_expanded);
                  },
                ),
              ),
              if (_expanded) for (final b in rest) _block(b),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kolay Mod ana eylemleri: Fırsatlar · Kartım · Etkinlikler · Havuzlar (72 px, 20 px etiket).
class HomeEasyShortcuts extends StatelessWidget {
  const HomeEasyShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final items = [
      (l.homeEasyDeals, AppIcons.tag, p.tile1, Routes.opportunities),
      (l.homeEasyCard, AppIcons.wallet, p.tile2, Routes.card),
      (l.homeEasyEvents, AppIcons.calendar, p.tile3, Routes.events),
      (l.homeEasyPools, AppIcons.pool, p.tile4, Routes.pools),
    ];
    return Semantics(
      container: true,
      label: l.homeShortcutsSemantics,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Column(
          children: [
            for (final (label, icon, color, route) in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EasyShortcutCard(label: label, icon: icon, color: color, onTap: () => openRoute(context, route)),
              ),
          ],
        ),
      ),
    );
  }
}

class _EasyShortcutCard extends StatelessWidget {
  const _EasyShortcutCard({required this.label, required this.icon, required this.color, required this.onTap});

  final String label, icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        radius: AppRadii.lg,
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              IconTile(icon: icon, color: color, size: 48, radius: 14, iconSize: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(20, weight: FontWeight.w800, color: p.ink),
                ),
              ),
              AppIcon(AppIcons.chevronRight, size: 22, color: p.mut, strokeWidth: 2.4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kolay Mod görev satırı: ikon + başlık/alt başlık + büyük puan rozeti.
class HomeEasyTaskRow extends StatelessWidget {
  const HomeEasyTaskRow({super.key, required this.task});

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
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => openLink(context, task.link),
      child: Row(
        children: [
          ProgressRing(value: task.progress, color: accent, child: AppIcon(HomeIcons.of(task.icon), size: 22, color: accent)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppTypography.body(18, weight: FontWeight.w800, color: p.ink, height: 1.2)),
                if (task.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(task.subtitle, style: AppTypography.body(14, color: p.mut)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          BuanPointsBadge(points: task.points, minWidth: 84, height: 36, fontSize: 17),
        ],
      ),
    );
  }
}

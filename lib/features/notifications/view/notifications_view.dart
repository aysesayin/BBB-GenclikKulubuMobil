import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/notifications/app_notification.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../l10n/l10n.dart';
import '../../home/home_links.dart';
import '../view_model/notifications_view_model.dart';
import '../widgets/notification_tile.dart';

/// B3 · Bildirimler (tam ekran).
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => NotificationsViewModel(sl<NotificationRepository>())..load(), child: const _Body());
}

String notificationCategoryLabel(AppLocalizations l, NotificationCategory c) => switch (c) {
  NotificationCategory.earn => l.notifCatEarn,
  NotificationCategory.opportunity => l.notifCatOpportunity,
  NotificationCategory.event => l.notifCatEvent,
  NotificationCategory.reservation => l.notifCatReservation,
  NotificationCategory.announcement => l.notifCatAnnouncement,
};

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<NotificationsViewModel>();
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(
            title: l.notifTitle,
            trailing: [
              TextButton(
                onPressed: vm.hasUnread && !vm.readingAll
                    ? () async {
                        if (await vm.readAll()) Haptics.selection();
                      }
                    : null,
                style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 10)),
                child: Text(
                  l.notifReadAll,
                  style: AppTypography.body(14, weight: FontWeight.w900, color: vm.hasUnread ? p.teal : p.mut),
                ),
              ),
            ],
          ),
          Semantics(
            container: true,
            label: l.notifCategorySemantics,
            child: PillRow(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              children: [
                FilterPill(label: l.commonAll, selected: vm.category == null, onTap: () => vm.selectCategory(null)),
                for (final c in NotificationCategory.values)
                  FilterPill(label: notificationCategoryLabel(l, c), selected: vm.category == c, onTap: () => vm.selectCategory(c)),
              ],
            ),
          ),
          Expanded(
            child: ViewStateBuilder<List<AppNotification>>(
              state: vm.state,
              onRetry: vm.refresh,
              skeleton: (_) => const NotificationsSkeleton(),
              builder: (context, _, {required offline}) => _List(vm: vm, offline: offline),
            ),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.vm, required this.offline});

  final NotificationsViewModel vm;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final sections = vm.sections;
    final locale = Localizations.localeOf(context).languageCode;
    if (sections.isEmpty) {
      return EmptyState(title: l.notifEmptyTitle, message: l.notifEmptyMessage);
    }
    String header(NotificationGroup g) => trUpper(switch (g) {
      NotificationGroup.today => l.notifGroupToday,
      NotificationGroup.yesterday => l.notifGroupYesterday,
      NotificationGroup.thisWeek => l.notifGroupThisWeek,
      NotificationGroup.earlier => l.notifGroupEarlier,
    });
    String time(NotificationGroup g, DateTime t) => switch (g) {
      NotificationGroup.today || NotificationGroup.yesterday => Fmt.time(t, locale),
      NotificationGroup.thisWeek => Fmt.weekdayShort(t, locale),
      NotificationGroup.earlier => Fmt.dayMonth(t, locale),
    };
    return RefreshIndicator(
      onRefresh: vm.refresh,
      color: p.teal,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          if (offline) const OfflineBanner(margin: EdgeInsets.only(bottom: 8)),
          for (final s in vm.sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Semantics(
                header: true,
                child: Text(
                  header(s.group),
                  style: AppTypography.body(13, weight: FontWeight.w900, color: p.mut).copyWith(letterSpacing: .6),
                ),
              ),
            ),
            for (final n in s.items)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: NotificationTile(
                  item: n,
                  meta: l.notifMeta(time(s.group, n.createdAt), notificationCategoryLabel(l, n.category)),
                  onTap: () {
                    vm.markRead(n.id);
                    openLink(context, n.link);
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

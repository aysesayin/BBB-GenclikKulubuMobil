import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../view_model/buan_view_model.dart';
import '../widgets/buan_icons.dart';
import '../widgets/task_card.dart';

/// Kolay Mod BUAN sekmesi: büyük bakiye + TEK dikey görev listesi (sekme yok);
/// Pazar / Lig / Rozetler listenin altında üç büyük tam genişlik buton.
class BuanEasyBody extends StatelessWidget {
  const BuanEasyBody({super.key, required this.data, required this.balance, required this.offline});

  final BuanHomeData data;
  final int balance;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BuanViewModel>();
    final l = context.l10n;
    final mq = MediaQuery.paddingOf(context);
    final tasks = vm.allTasks;
    return RefreshIndicator(
      onRefresh: vm.refresh,
      edgeOffset: mq.top,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, mq.top + 12, 20, AppSpacing.tabBarHeight + mq.bottom + 28),
        children: [
          _EasyBalance(balance: balance, onHistory: () => context.push(Routes.history)),
          if (offline) const OfflineBanner(margin: EdgeInsets.only(top: 12)),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(l.buanTabEarn, style: AppTypography.display(24, color: context.palette.ink)),
          ),
          const SizedBox(height: 10),
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCard(task: t, onTap: () => context.push(BuanViewModel.routeFor(t))),
            ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: l.buanEasyMoreLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton.buan(label: l.buanMarketTitle, icon: BuanIcons.bag, onPressed: () => context.push(Routes.market)),
                const SizedBox(height: 12),
                AppButton(
                  label: l.buanLeagueTitle,
                  icon: BuanIcons.trophy,
                  variant: AppButtonVariant.outlineInk,
                  onPressed: () => context.push(Routes.league),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: l.buanBadgesTitle,
                  icon: BuanIcons.star,
                  variant: AppButtonVariant.outlineInk,
                  onPressed: () => context.push(Routes.badges),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolay Mod bakiye kartı: mor gradyan, büyük sayı, "Geçmiş" butonu. Kaydırmayla daralmaz.
class _EasyBalance extends StatelessWidget {
  const _EasyBalance({required this.balance, required this.onHistory});

  final int balance;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Semantics(
      container: true,
      label: l.buanBalanceSemantics(Fmt.number(balance)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: p.buanGradient, borderRadius: BorderRadius.circular(AppRadii.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(l.buanHomeTitle, style: AppTypography.display(20, color: p.onBuan)),
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Row(
                children: [
                  const BuanCoin(size: 40, ring: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: CountUpText(value: balance, animate: false, style: AppTypography.number(44, height: 1.05, color: p.onBuan)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: l.buanHomeHistory,
              semanticLabel: l.buanHomeHistorySemantics,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.medium,
              onPressed: onHistory,
            ),
          ],
        ),
      ),
    );
  }
}

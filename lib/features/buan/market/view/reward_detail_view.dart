import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_reward.dart';
import '../../../../data/repositories/buan_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_skeleton.dart';
import '../../widgets/buan_ui.dart';
import '../view_model/reward_detail_view_model.dart';
import '../widgets/redeem_sheet.dart';
import '../widgets/redeem_success.dart';
import '../widgets/reward_art.dart';

/// E3 · Ödül detayı + takas onayı (tam ekran).
class RewardDetailView extends StatelessWidget {
  const RewardDetailView({super.key, required this.rewardId});

  final String rewardId;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => RewardDetailViewModel(sl<BuanRepository>(), rewardId)..load(), child: const RewardDetailBody());
}

/// Testlerde sağlayıcıyla doğrudan kurulabilmesi için açık.
class RewardDetailBody extends StatelessWidget {
  const RewardDetailBody({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RewardDetailViewModel>();
    final p = context.palette;
    final result = vm.result;
    final reward = vm.reward;
    return Scaffold(
      backgroundColor: p.sf,
      body: Stack(
        children: [
          Positioned.fill(
            child: ViewStateBuilder<BuanReward>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const BuanSkeleton(heroHeight: 270, rows: 3, rowHeight: 90),
              builder: (context, data, {required offline}) => _Content(reward: data, offline: offline),
            ),
          ),
          if (vm.state.dataOrNull == null) Positioned(top: MediaQuery.paddingOf(context).top + 8, left: 12, child: const _BackButton()),
          if (result != null && reward != null)
            Positioned.fill(
              child: RedeemSuccess(
                reward: reward,
                result: result,
                balanceFrom: vm.balanceBefore,
                balanceTo: vm.balance,
                onCodes: () => context.go(Routes.myOpportunities),
                onBack: () => context.pop(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppIconButton(
      icon: AppIcons.back,
      semanticLabel: context.l10n.commonBack,
      background: p.paper.withValues(alpha: .92),
      color: p.onTile,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.reward, required this.offline});

  final BuanReward reward;
  final bool offline;

  Future<void> _buy(BuildContext context) async {
    final vm = context.read<RewardDetailViewModel>();
    await AuthGate.guard(context, () => RedeemSheet.show(context, vm));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RewardDetailViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final String label;
    if (vm.soldOut) {
      label = l.buanMarketSoldOut;
    } else if (!vm.canAfford) {
      label = l.buanRewardMissing(Fmt.number(vm.missing));
    } else {
      label = l.buanRewardCta;
    }
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  children: [
                    RewardArt(reward: reward),
                    Positioned(top: MediaQuery.paddingOf(context).top + 8, left: 12, child: const _BackButton()),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.sf,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: _Details(reward: reward, offline: offline),
                  ),
                ),
              ],
            ),
          ),
        ),
        StickyBottomBar(
          child: AppButton.buan(label: label, onPressed: vm.canRedeem ? () => _buy(context) : null),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.reward, required this.offline});

  final BuanReward reward;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RewardDetailViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final left = reward.remaining;
    final chips = <(String, Color, Color)>[
      if (reward.categoryLabel.isNotEmpty) (reward.categoryLabel, p.sf2, p.ink),
      if (left != null) (reward.firstN != null ? l.buanRewardSeatsLeft(left) : l.buanRewardStockLeft(left), p.pinkS, p.pinkT),
      if (reward.perPersonLimit != null) (l.buanRewardPerPerson(reward.perPersonPeriod.name, reward.perPersonLimit!), p.sf2, p.ink),
      if (reward.limitNote case final n? when n.isNotEmpty) (n, p.sf2, p.ink),
    ];
    final afterColor = vm.balanceAfter >= 0 ? p.grnT : p.pinkT;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (offline)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: OfflineBanner(margin: EdgeInsets.zero),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (text, bg, fg) in chips)
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    text,
                    style: AppTypography.body(12, weight: FontWeight.w900, color: fg),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(reward.title, style: AppTypography.display(28, height: 1.08, color: p.ink)),
        ),
        if (reward.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            reward.description,
            style: AppTypography.body(15, weight: FontWeight.w600, height: 1.5, color: p.mut),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(AppRadii.lg)),
          child: Column(
            children: [
              _Line(
                label: l.buanRewardPrice,
                value: l.buanAmount(Fmt.number(reward.price)),
                labelStyle: AppTypography.body(15, weight: FontWeight.w800, color: p.ink),
                valueStyle: AppTypography.number(22, color: p.purT),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, thickness: 1, color: p.line),
              const SizedBox(height: 10),
              _Line(
                label: l.buanRewardBalance,
                value: Fmt.number(vm.balance),
                labelStyle: AppTypography.body(14, weight: FontWeight.w800, color: p.mut),
                valueStyle: AppTypography.number(14, weight: FontWeight.w800, color: p.mut),
              ),
              const SizedBox(height: 10),
              _Line(
                label: l.buanRewardAfter,
                value: Fmt.signed(vm.balanceAfter).replaceFirst('+', ''),
                labelStyle: AppTypography.body(14, weight: FontWeight.w900, color: p.ink),
                valueStyle: AppTypography.number(14, color: afterColor),
              ),
            ],
          ),
        ),
        if (reward.rules.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(l.buanRewardRules, style: AppTypography.display(20, color: p.ink)),
          ),
          const SizedBox(height: 8),
          for (final r in reward.rules) BuanBullet(text: r),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, required this.labelStyle, required this.valueStyle});

  final String label, value;
  final TextStyle labelStyle, valueStyle;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, maxLines: 1, softWrap: false, style: valueStyle),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_icons.dart';
import '../../widgets/buan_ui.dart';
import '../view_model/reward_detail_view_model.dart';

/// "Takası onayla" alt sayfası. true döner → takas başarılı.
abstract final class RedeemSheet {
  static Future<bool> show(BuildContext context, RewardDetailViewModel vm) async {
    vm.beginRedeem();
    final ok = await AppSheet.show<bool>(
      context,
      builder: (_) => ChangeNotifierProvider<RewardDetailViewModel>.value(value: vm, child: const _Body()),
    );
    if (ok != true) vm.cancelRedeem();
    return ok ?? false;
  }
}

class _Body extends StatelessWidget {
  const _Body();

  Future<void> _confirm(BuildContext context, RewardDetailViewModel vm) async {
    final ok = await vm.redeem();
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      Haptics.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RewardDetailViewModel>();
    final reward = vm.reward!;
    final p = context.palette;
    final l = context.l10n;
    final busy = vm.redeeming;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l.buanRedeemTitle, style: AppTypography.display(24, color: p.ink)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              IconTile(icon: BuanIcons.byKey(reward.icon), color: buanTile(p, reward.tile), size: 52, radius: 16, iconSize: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reward.title,
                  style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: l.buanAmount(Fmt.signed(-reward.price)),
                excludeSemantics: true,
                child: Text(Fmt.signed(-reward.price), maxLines: 1, softWrap: false, style: AppTypography.number(15, color: p.purT)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          // Başarı anında bakiye güncellenir; sheet kapanana dek eski önizleme korunur.
          vm.result == null
              ? l.buanRedeemMessage(Fmt.number(vm.balance), Fmt.number(vm.balanceAfter))
              : l.buanRedeemMessage(Fmt.number(vm.balanceBefore), Fmt.number(vm.balance)),
          style: AppTypography.body(14, color: p.mut),
        ),
        if (vm.redeemError case final e?) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: p.errorSoft, borderRadius: BorderRadius.circular(AppRadii.md)),
              child: Row(
                children: [
                  AppIcon(AppIcons.info, size: 18, color: p.errorText, strokeWidth: 2.6),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessageOf(context, e),
                      style: AppTypography.body(13, weight: FontWeight.w900, color: p.errorText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 10,
              child: AppButton(
                label: l.buanRedeemCancel,
                variant: AppButtonVariant.outlineInk,
                onPressed: busy ? null : () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 14,
              child: AppButton(label: l.buanRedeemConfirm, busy: busy, onPressed: vm.canRedeem ? () => _confirm(context, vm) : null),
            ),
          ],
        ),
      ],
    );
  }
}

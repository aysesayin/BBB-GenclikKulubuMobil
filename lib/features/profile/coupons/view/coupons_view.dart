import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/repositories/coupon_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/profile_layout.dart';
import '../../widgets/profile_ui.dart';
import '../view_model/coupons_view_model.dart';
import '../widgets/coupon_code_form.dart';
import '../widgets/coupon_widgets.dart';

/// I5 · Kuponlarım (Profil sekmesi içinde; alt navigasyon görünür).
class CouponsView extends StatelessWidget {
  const CouponsView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => CouponsViewModel(sl<CouponRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CouponsViewModel>();
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: context.l10n.profileCouponsTitle),
          Expanded(
            child: ViewStateBuilder<CouponsData>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const ProfileListSkeleton(blocks: [140, 180, 170]),
              builder: (context, data, {required offline}) => _Content(data: data, offline: offline),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.offline});

  final CouponsData data;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CouponsViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final empty = AppTypography.body(14, color: p.mut);
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: profileTabPadding(context),
        children: [
          if (offline) const OfflineBanner(),
          CouponBalanceCard(balance: data.wallet.balance),
          const CouponCodeForm(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CapsLabel(l.profileCouponsSection),
                const SizedBox(height: 10),
                if (data.wallet.items.isEmpty) Text(l.profileCouponsEmpty, style: empty),
                for (var i = 0; i < data.wallet.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  CouponTile(coupon: data.wallet.items[i]),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CapsLabel(l.profileMovementsSection),
                const SizedBox(height: 6),
                if (data.movements.isEmpty) Text(l.profileMovementsEmpty, style: empty),
                for (final m in data.movements) CouponMovementRow(movement: m),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

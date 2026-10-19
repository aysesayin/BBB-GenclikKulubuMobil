import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/profile_ui.dart';
import '../view_model/discounts_view_model.dart';
import '../widgets/discount_form.dart';
import '../widgets/discount_tile.dart';

/// I3 · İndirim Tanımla (tam ekran).
class DiscountsView extends StatelessWidget {
  const DiscountsView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => DiscountsViewModel(sl<ProfileRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  Future<void> _submit(BuildContext context) async {
    final vm = context.read<DiscountsViewModel>();
    final l = context.l10n;
    final ok = await vm.submit();
    if (!ok || !context.mounted) return;
    Haptics.medium();
    showProfileSnack(context, l.profileDiscountSubmitted);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscountsViewModel>();
    final l = context.l10n;
    final hasData = vm.state.dataOrNull != null;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: l.profileDiscountsTitle),
          Expanded(
            child: ViewStateBuilder<DiscountsData>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const ProfileListSkeleton(blocks: [64 * 3 + 20, 380]),
              builder: (context, data, {required offline}) => _Content(data: data, offline: offline),
            ),
          ),
          if (hasData)
            BottomCtaBar(
              child: AppButton(label: l.profileDiscountSubmit, busy: vm.submitting, onPressed: () => _submit(context)),
            ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.offline});

  final DiscountsData data;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<DiscountsViewModel>();
    final p = context.palette;
    final l = context.l10n;
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        children: [
          if (offline) const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CapsLabel(l.profileDiscountsMine),
                const SizedBox(height: 10),
                if (data.mine.isEmpty)
                  Text(l.profileDiscountsEmpty, style: AppTypography.body(14, color: p.mut))
                else
                  for (final d in data.mine) ...[
                    DiscountTile(discount: d, today: vm.today, onRenew: () => vm.renew(d)),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
          DiscountForm(data: data),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/sports.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/service_row_card.dart';
import '../../widgets/svc_format.dart';
import '../../widgets/svc_navigation.dart';
import '../view_model/tennis_view_model.dart';

/// Tenis ürün listesi (Spor ekranının ikinci sekmesi). [TennisViewModel] üst ağaçtan gelir.
class TennisList extends StatelessWidget {
  const TennisList({super.key, required this.ageGroupId});

  final String? ageGroupId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TennisViewModel>();
    final p = context.palette;
    final l = context.l10n;
    return ViewStateBuilder<List<TennisProduct>>(
      state: vm.state,
      onRetry: vm.load,
      skeleton: (_) => Shimmer(
        child: Column(children: [for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 72, radius: 20))]),
      ),
      empty: (_) => SizedBox(height: 360, child: EmptyState(title: l.svcSportsEmptyTitle, message: l.svcSportsEmptyMessage)),
      builder: (context, _, {required offline}) {
        final items = vm.visible(ageGroupId);
        if (items.isEmpty) return SizedBox(height: 360, child: EmptyState(title: l.svcSportsEmptyTitle, message: l.svcSportsEmptyMessage));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (offline) const OfflineBanner(margin: EdgeInsets.only(bottom: 10)),
            for (final t in items) ...[
              ServiceRowCard(
                icon: AppIcons.tennis,
                tileColor: SvcFmt.tile(p, t.tile),
                title: t.name,
                subtitle: t.subtitle,
                semanticLabel: '${t.name}, ${t.subtitle}',
                onTap: () => openSessions(context, t.itemId),
                trailing: AppIcon(AppIcons.chevronRight, size: 18, color: p.mut, strokeWidth: 2.4),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

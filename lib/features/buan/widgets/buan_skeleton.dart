import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// BUAN ekranları için ortak iskelet: isteğe bağlı üst blok + kart satırları.
class BuanSkeleton extends StatelessWidget {
  const BuanSkeleton({super.key, this.heroHeight = 0, this.rows = 5, this.rowHeight = 76, this.grid = false});

  final double heroHeight, rowHeight;
  final int rows;

  /// true → 2 sütunlu ödül ızgarası iskeleti.
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          if (heroHeight > 0)
            SkeletonBox(height: heroHeight + top, radius: 32)
          else
            Padding(
              padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
              child: const Row(
                children: [SkeletonBox(width: 44, height: 44, circle: true), SizedBox(width: 12), SkeletonBox(width: 180, height: 26)],
              ),
            ),
          const SizedBox(height: 16),
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, 10),
              child: grid
                  ? Row(
                      children: [
                        Expanded(
                          child: SkeletonBox(height: rowHeight, radius: AppRadii.lg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SkeletonBox(height: rowHeight, radius: AppRadii.lg),
                        ),
                      ],
                    )
                  : SkeletonBox(height: rowHeight, radius: AppRadii.lg),
            ),
        ],
      ),
    );
  }
}

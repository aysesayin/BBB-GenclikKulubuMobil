import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Liste ekranları için genel iskelet: bölüm etiketi + kart blokları.
class ProfileListSkeleton extends StatelessWidget {
  const ProfileListSkeleton({super.key, this.blocks = const [240, 300, 150]});

  final List<double> blocks;

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      children: [
        for (final h in blocks) ...[
          const Padding(padding: EdgeInsets.only(left: 4, bottom: 10), child: SkeletonBox(width: 140, height: 13)),
          SkeletonBox(height: h, radius: 22),
          const SizedBox(height: 22),
        ],
      ],
    ),
  );
}

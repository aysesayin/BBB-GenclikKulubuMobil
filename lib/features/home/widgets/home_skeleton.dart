import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// S1 · Keşfet yükleniyor (KesfetYukleniyor.dc.html) — shimmer 1200 ms.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: context.palette.bg,
      child: Shimmer(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: top + 12),
          child: LayoutBuilder(
            builder: (context, c) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      SkeletonBox(width: 44, height: 44, circle: true),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 80, height: 12, radius: 6),
                            SizedBox(height: 6),
                            SkeletonBox(width: 120, height: 18, radius: 9),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      SkeletonBox(width: 92, height: 36, radius: 18),
                    ],
                  ),
                ),
                const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 0), child: SkeletonBox(height: 48, radius: 24)),
                _row(top: 18, count: 5, gap: 14, child: const SkeletonBox(width: 64, height: 64, circle: true)),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 180, height: 20, radius: 10)),
                ),
                _row(top: 12, count: 3, gap: 12, child: const SkeletonBox(width: 158, height: 138, radius: 22)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: SkeletonBox(height: ((c.maxWidth - 40) / 1.75).roundToDouble(), radius: 26),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        const Expanded(child: Center(child: SkeletonBox(width: 58, height: 58, radius: 20))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _row({required double top, required int count, required double gap, required Widget child}) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.fromLTRB(20, top, 20, 0),
    child: Row(
      children: [
        for (var i = 0; i < count; i++) ...[if (i > 0) SizedBox(width: gap), child],
      ],
    ),
  );
}

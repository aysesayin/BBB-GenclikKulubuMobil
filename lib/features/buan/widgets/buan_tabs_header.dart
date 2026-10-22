import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';

/// Hero'nun altında sabit kalan Kazan / Pazar / Lig / Rozet sekmeleri.
class BuanTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const BuanTabsHeaderDelegate({required this.onChanged});

  static const height = 64.0;

  final ValueChanged<int> onChanged;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final l = context.l10n;
    return ColoredBox(
      color: context.palette.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Semantics(
          container: true,
          label: l.buanHomeSectionsLabel,
          child: SegmentedTabs(
            labels: [l.buanTabEarn, l.buanTabMarket, l.buanTabLeague, l.buanTabBadges],
            index: 0,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(BuanTabsHeaderDelegate old) => old.onChanged != onChanged;
}

/// Bölüm başlığı: "Günlük" + sağda not ("Gece 00:00'da yenilenir").
class BuanGroupHeader extends StatelessWidget {
  const BuanGroupHeader({super.key, required this.title, required this.note});

  final String title, note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppTypography.display(20, color: p.ink)),
            ),
          ),
          if (note.isNotEmpty)
            Flexible(
              child: Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
              ),
            ),
        ],
      ),
    );
  }
}

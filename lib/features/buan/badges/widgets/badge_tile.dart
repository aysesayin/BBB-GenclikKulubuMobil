import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_badge.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_icons.dart';
import '../../widgets/buan_ui.dart';

/// Rozet: kazanıldıysa renkli sticker (ink çerçeve + sert gölge + hafif eğim),
/// kilitliyse gri zemin + kesikli çerçeve + kilit + koşul metni.
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge, required this.index});

  final BuanBadge badge;

  /// Eğim dizisindeki sıra (−5°, 3°, −2°, 4°, −4°, 2°, −3°).
  final int index;

  static const _tilts = [-5, 3, -2, 4, -4, 2, -3];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final earnedDetail = badge.description.isNotEmpty
        ? badge.description
        : (badge.earnedAt != null ? DateFormat.yMMMM(locale).format(badge.earnedAt!.toLocal()) : '');
    final subtitle = badge.earned ? earnedDetail : l.buanBadgesLocked(badge.condition);
    final icon = AppIcon(BuanIcons.byKey(badge.icon), size: 40, color: badge.earned ? p.onTile : p.mut, strokeWidth: 2);
    final Widget sticker = badge.earned
        ? Transform.rotate(
            angle: _tilts[index % _tilts.length] * math.pi / 180,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: buanTile(p, badge.tile),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: p.onTile, width: 3),
                boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(4, 4))],
              ),
              alignment: Alignment.center,
              child: icon,
            ),
          )
        : SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DashedRRectBorder(
                    color: p.line,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: p.sf2, borderRadius: BorderRadius.circular(28)),
                      child: Center(child: icon),
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: p.sf,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.line, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(AppIcons.lock, size: 14, color: p.mut, strokeWidth: 2.6),
                  ),
                ),
              ],
            ),
          );
    return Semantics(
      label: badge.earned
          ? l.buanBadgesEarnedSemantics(badge.title, earnedDetail)
          : l.buanBadgesLockedSemantics(badge.title, badge.condition),
      excludeSemantics: true,
      child: Column(
        children: [
          sticker,
          const SizedBox(height: 8),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: AppTypography.body(13, weight: FontWeight.w900, height: 1.2, color: p.ink),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.body(11, height: 1.3, color: p.mut),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'holo_card.dart';

/// Misafir yumuşak duvarı (S2): kart önizlemesi soluk görünür, CTA kayıt sheet'ini açar.
class CardGuestWall extends StatelessWidget {
  const CardGuestWall({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: p.bg,
      body: ListView(
        padding: EdgeInsets.only(bottom: bottom + 24),
        children: [
          TabScreenHeader(title: l.tabCard),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Opacity(
              opacity: .55,
              child: HoloCard(
                live: false,
                name: l.cardGuestName,
                memberNo: l.cardGuestMemberNo,
                levelLabel: l.cardLevelBadge(1, l.cardGuestLevel),
                semanticLabel: l.cardGuestPreview,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: AppCard(
              radius: AppRadii.xl,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Mascot(size: 76),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(l.cardGuestTitle, style: AppTypography.display(24, height: 1.05, color: p.ink)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l.cardGuestMessage, style: AppTypography.body(15, color: p.mut, height: 1.4)),
                  const SizedBox(height: 18),
                  AppButton(
                    label: l.cardGuestCta,
                    onPressed: () => AuthGate.show(context, title: l.cardGuestTitle),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

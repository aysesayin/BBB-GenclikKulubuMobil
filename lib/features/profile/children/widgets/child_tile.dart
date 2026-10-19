import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/profile/child_profile.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/profile_ui.dart';

/// Çocuk satırı: 52 px baş harf dairesi, ad, "9 yaş · 2 aktif başvuru", MERNİS hapı.
class ChildTile extends StatelessWidget {
  const ChildTile({super.key, required this.child, required this.index});

  final ChildProfile child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final tones = [p.tile6, p.tile2, p.tile4, p.tile5, p.tile1, p.tile3];
    final initial = child.initial.isNotEmpty ? child.initial : (child.displayName.isEmpty ? '?' : child.displayName.characters.first);
    final sub = [l.profileChildAge(child.age), if (child.note.isNotEmpty) child.note].join(' · ');
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.lg)),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: tones[index % tones.length], shape: BoxShape.circle),
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: Text(initial, style: AppTypography.display(20, color: p.onTile)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TitleSubtitle(title: child.displayName, subtitle: sub, titleSize: 16),
            ),
            if (child.mernisVerified) ...[
              const SizedBox(width: 8),
              Semantics(
                label: l.profileChildMernisSemantics,
                excludeSemantics: true,
                child: StatusPill(label: l.profileChildMernis, icon: AppIcons.check, background: p.grnS, foreground: p.grnT, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

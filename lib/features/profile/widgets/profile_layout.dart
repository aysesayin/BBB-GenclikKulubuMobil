import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'profile_icons.dart';

/// Profil sekmesi zemini: üstte nane blob (tasarım: 420×360, top −170, left −20).
class ProfileBackdrop extends StatelessWidget {
  const ProfileBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.bg,
      child: Stack(
        children: [
          Positioned(
            top: -170,
            left: -20,
            child: SvgArt(
              '<svg viewBox="0 0 420 360"><path d="M220 20c110 0 190 70 180 170s-90 170-200 160S10 270 30 170 110 20 220 20z" '
              'fill="${p.mint.hex}"/></svg>',
              width: 420,
              height: 360,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Sağ üstte 44 px yüzey zeminli ayarlar butonu (güvenli alan + 8).
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({super.key, this.onSettings});

  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 0),
      child: SizedBox(
        height: 44,
        child: Align(
          alignment: Alignment.centerRight,
          child: onSettings == null
              ? null
              : AppIconButton(
                  icon: ProfileIcons.sliders,
                  semanticLabel: context.l10n.profileSettingsSemantics,
                  background: p.sf,
                  onPressed: onSettings,
                ),
        ),
      ),
    );
  }
}

/// Sekme alt boşluğu (alt navigasyon 88 px + güvenli alan).
EdgeInsets profileTabPadding(BuildContext context) =>
    EdgeInsets.only(bottom: AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom);

/// Profil iskeleti (yükleniyor).
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 60, 20, 0),
      children: const [
        Center(child: SkeletonBox(width: 108, height: 108, circle: true)),
        SizedBox(height: 14),
        Center(child: SkeletonBox(width: 170, height: 28)),
        SizedBox(height: 10),
        Center(child: SkeletonBox(width: 200, height: 16)),
        SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 72, radius: 20)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(height: 72, radius: 20)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(height: 72, radius: 20)),
          ],
        ),
        SizedBox(height: 16),
        SkeletonBox(height: 128, radius: 22),
        SizedBox(height: 16),
        SkeletonBox(height: 340, radius: 22),
      ],
    ),
  );
}

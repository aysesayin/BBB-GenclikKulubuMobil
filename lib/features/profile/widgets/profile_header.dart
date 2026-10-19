import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/profile/user_profile.dart';
import '../../../l10n/l10n.dart';
import 'profile_icons.dart';

/// Profil başlığı: blob avatar (baş harfler) + düzenle butonu, ad, seviye çipi, üye no, maskeli TCKN.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, required this.onEditAvatar, this.avatarBusy = false});

  final UserProfile user;
  final VoidCallback onEditAvatar;
  final bool avatarBusy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Column(
      children: [
        ProfileAvatar(initials: user.initials, avatarUrl: user.avatarUrl, onEdit: onEditAvatar, busy: avatarBusy),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: AppTypography.display(28, height: 1, color: p.ink),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            if (user.levelName.isNotEmpty)
              Transform.rotate(
                angle: -3 * math.pi / 180,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.cta,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.onTile, width: 2),
                  ),
                  child: Text(
                    l.profileLevelChip(user.level, user.levelName),
                    style: AppTypography.body(12, weight: FontWeight.w900, color: p.onCta),
                  ),
                ),
              ),
            if (user.memberNo.isNotEmpty)
              Text(
                l.profileMemberNo(user.memberNo),
                style: AppTypography.body(13, weight: FontWeight.w800, color: p.mut),
              ),
          ],
        ),
        if (user.tcknMasked.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            l.profileTckn(user.displayTckn),
            style: AppTypography.number(12, weight: FontWeight.w700, color: p.mut),
          ),
        ],
      ],
    );
  }
}

/// 108 px blob avatar. [onEdit] null ise düzenle butonu gizlenir.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.initials, this.avatarUrl, this.onEdit, this.busy = false, this.icon});

  final String initials;
  final String? avatarUrl;
  final VoidCallback? onEdit;
  final bool busy;

  /// Baş harf yerine ikon (misafir).
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final url = avatarUrl;
    return SizedBox.square(
      dimension: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgArt(
            '<svg viewBox="0 0 108 108"><path d="M58 4c28 2 46 22 46 50s-20 50-50 50S4 84 4 54 26 2 58 4z" '
            'fill="${p.tile6.hex}" stroke="${p.onTile.hex}" stroke-width="3"/></svg>',
            width: 108,
            height: 108,
          ),
          Positioned.fill(
            child: Center(
              child: url != null && url.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(imageUrl: url, width: 92, height: 92, fit: BoxFit.cover),
                    )
                  : icon != null
                  ? AppIcon(icon!, size: 44, color: p.onTile, strokeWidth: 2.2)
                  : ExcludeSemantics(
                      child: Text(initials, style: AppTypography.display(40, color: p.onTile)),
                    ),
            ),
          ),
          if (onEdit != null)
            Positioned(
              right: -4,
              bottom: 0,
              child: Semantics(
                button: true,
                label: context.l10n.profileEditAvatar,
                child: GestureDetector(
                  onTap: busy ? null : onEdit,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.buanFill,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.bg, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: busy
                          ? SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onBuan))
                          : AppIcon(ProfileIcons.pencil, size: 18, color: p.onBuan, strokeWidth: 2.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

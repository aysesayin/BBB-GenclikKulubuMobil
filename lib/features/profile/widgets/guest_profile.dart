import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../l10n/l10n.dart';
import 'legal_links.dart';
import 'profile_header.dart';
import 'profile_icons.dart';
import 'profile_layout.dart';
import 'profile_menu.dart';
import 'profile_ui.dart';
import 'theme_mode_selector.dart';

/// Misafir profili: kayıt / giriş çağrısı + herkese açık öğeler (anketler, yasal metinler, tema).
// TODO(varsayım): Tasarımda misafir profil varyantı yok; AuthGate sheet'inin dili ve renkleriyle kuruldu.
class GuestProfileBody extends StatelessWidget {
  const GuestProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final bonus = Fmt.number(sl<AppRepository>().current.welcomeBonus);
    return Scaffold(
      body: ProfileBackdrop(
        child: ListView(
          padding: profileTabPadding(context),
          children: [
            const ProfileTopBar(),
            const Center(
              child: ProfileAvatar(initials: '', icon: AppIcons.user),
            ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                l.profileGuestTitle,
                textAlign: TextAlign.center,
                style: AppTypography.display(28, height: 1.05, color: p.ink),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l.profileGuestMessage,
                textAlign: TextAlign.center,
                style: AppTypography.body(15, color: p.mut, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  AppButton(label: l.guestRegister(bonus), onPressed: () => context.push(Routes.interests)),
                  const SizedBox(height: 8),
                  AppButton(
                    label: l.guestLogin,
                    variant: AppButtonVariant.outlineInk,
                    size: AppButtonSize.medium,
                    onPressed: () => context.push(Routes.login),
                  ),
                ],
              ),
            ),
            CapsLabel(l.profileGuestSection, padding: const EdgeInsets.fromLTRB(24, 24, 24, 8)),
            ProfileMenu(
              label: l.profileMenuLabel,
              margin: AppSpacing.screenPadding,
              items: [
                ProfileMenuItem(label: l.profileMenuSurveys, icon: AppIcons.poll, tile: p.tile2, onTap: () => context.push(Routes.quiz)),
                ProfileMenuItem(
                  label: l.profileMenuLegalGuest,
                  icon: ProfileIcons.document,
                  tile: p.sf2,
                  iconColor: p.ink,
                  onTap: () => AppSheet.show<void>(context, builder: (_) => const LegalLinksCard()),
                ),
              ],
            ),
            CapsLabel(l.profileSectionAppearanceGuest, padding: const EdgeInsets.fromLTRB(24, 22, 24, 8)),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.lg)),
              child: const ThemeModeSelector(),
            ),
          ],
        ),
      ),
    );
  }
}

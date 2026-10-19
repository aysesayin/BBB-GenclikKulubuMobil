import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/profile_view_model.dart';
import '../widgets/confirm_sheet.dart';
import '../widgets/document_picker.dart';
import '../widgets/guest_profile.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_icons.dart';
import '../widgets/profile_layout.dart';
import '../widgets/profile_menu.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_ui.dart';

/// I1 · Profil sekmesi. Misafirde kayıt çağrılı varyant gösterilir.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final guest = context.select<SessionController, bool>((s) => s.isGuest);
    if (guest) return const GuestProfileBody();
    return ChangeNotifierProvider(create: (_) => ProfileViewModel(sl<ProfileRepository>())..load(), child: const _MemberBody());
  }
}

class _MemberBody extends StatelessWidget {
  const _MemberBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    return Scaffold(
      body: ProfileBackdrop(
        child: ViewStateBuilder<ProfileOverview>(
          state: vm.state,
          onRetry: vm.load,
          skeleton: (_) => const ProfileSkeleton(),
          builder: (context, data, {required offline}) => RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              padding: profileTabPadding(context),
              children: [
                ProfileTopBar(onSettings: () => context.push(Routes.settings)),
                if (offline) const OfflineBanner(margin: EdgeInsets.fromLTRB(16, 8, 16, 8)),
                ProfileHeader(user: data.user, avatarBusy: vm.avatarBusy, onEditAvatar: () => _editAvatar(context)),
                ProfileStatsRow(stats: data.stats),
                BadgeShowcase(stats: data.stats, onOpen: () => context.push(Routes.badges)),
                ProfileMenu(label: context.l10n.profileMenuLabel, items: _items(context, data)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ProfileMenuItem> _items(BuildContext context, ProfileOverview data) {
    final p = context.palette;
    final l = context.l10n;
    VoidCallback go(String route) =>
        () => context.push(route);
    final s = data.stats;
    return [
      ProfileMenuItem(
        label: l.profileMenuApplications,
        icon: ProfileIcons.applications,
        tile: p.tile3,
        badge: s.pendingPayments > 0 ? l.profilePendingPayments(s.pendingPayments) : null,
        onTap: go(Routes.applications),
      ),
      ProfileMenuItem(label: l.profileMenuOpportunities, icon: AppIcons.tag, tile: p.tile2, onTap: go(Routes.myOpportunities)),
      ProfileMenuItem(label: l.profileMenuCoupons, icon: ProfileIcons.coupon, tile: p.tile6, onTap: go(Routes.coupons)),
      ProfileMenuItem(label: l.profileMenuDiscounts, icon: ProfileIcons.percent, tile: p.tile5, onTap: go(Routes.discounts)),
      ProfileMenuItem(label: l.profileMenuChildren, icon: ProfileIcons.child, tile: p.tile1, onTap: go(Routes.children)),
      ProfileMenuItem(
        label: l.profileMenuSurveys,
        icon: AppIcons.poll,
        tile: p.tile2,
        badge: s.openSurveys > 0 ? l.profileOpenSurveys(s.openSurveys) : null,
        onTap: go(Routes.quiz),
      ),
      ProfileMenuItem(label: l.profileMenuSupport, icon: ProfileIcons.chat, tile: p.tile4, onTap: go(Routes.support)),
      ProfileMenuItem(label: l.profileMenuSettings, icon: ProfileIcons.sliders, tile: p.tile3, onTap: go(Routes.settings)),
      ProfileMenuItem(label: l.profileMenuLegal, icon: ProfileIcons.document, tile: p.sf2, iconColor: p.ink, onTap: go(Routes.support)),
      ProfileMenuItem(
        label: l.profileMenuLogout,
        icon: ProfileIcons.logout,
        tile: p.pinkS,
        iconColor: p.pinkT,
        foreground: p.pinkT,
        onTap: () => _logout(context),
      ),
    ];
  }

  Future<void> _editAvatar(BuildContext context) async {
    final vm = context.read<ProfileViewModel>();
    final file = await pickDocument(context);
    if (file == null || !context.mounted) return;
    final l = context.l10n;
    final error = await vm.uploadAvatar(path: file.path, fileName: file.name);
    if (!context.mounted) return;
    showProfileSnack(context, error == null ? l.profileAvatarUpdated : errorMessageOf(context, error));
  }

  Future<void> _logout(BuildContext context) async {
    final l = context.l10n;
    final ok = await showConfirmSheet(
      context,
      title: l.profileLogoutTitle,
      message: l.profileLogoutMessage,
      confirmLabel: l.profileMenuLogout,
    );
    if (!ok || !context.mounted) return;
    final vm = context.read<ProfileViewModel>();
    final session = context.read<SessionController>();
    final router = GoRouter.of(context);
    await vm.signOut(session);
    router.go(Routes.welcome);
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_feed.dart';
import '../../../l10n/l10n.dart';
import '../view_model/home_view_model.dart';

/// Keşfet başlığı: avatar · selam + ad (Expanded) · BUAN çipi · zil.
/// Seri çipi BUAN sekmesinde yaşar; 360 px'te sığmadığı için başlıkta yok.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.feed, required this.greeting, this.topInset, this.large = false});

  final HomeFeed feed;
  final HomeGreeting greeting;

  /// null → güvenli alan + 12 (tasarım 56 px).
  final double? topInset;

  /// Kolay Mod: büyük selam (16 / 28 px).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    // TODO(varsayım): Misafirde (user null) ad yerine "Gezgin" gösterilir, BUAN çipi gizlenir.
    final user = feed.user;
    final wallet = feed.wallet;
    final hello = switch (greeting) {
      HomeGreeting.morning => l.homeGreetingMorning,
      HomeGreeting.day => l.homeGreetingDay,
      HomeGreeting.evening => l.homeGreetingEvening,
      HomeGreeting.night => l.homeGreetingNight,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topInset ?? MediaQuery.paddingOf(context).top + 12, 20, 0),
      child: Row(
        children: [
          _Avatar(initials: user == null ? null : HomeViewModel.initialsOf(user)),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hello,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(large ? 16 : 13, color: p.mut),
                  ),
                  Text(
                    user?.firstName ?? l.homeGuestName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(large ? 28 : 22, color: p.ink),
                  ),
                ],
              ),
            ),
          ),
          if (wallet != null) ...[
            const SizedBox(width: 10),
            BuanBalanceChip(balance: wallet.balance, onTap: () => context.go(Routes.buan)),
          ],
          const SizedBox(width: 10),
          AppIconButton(
            icon: AppIcons.bell,
            semanticLabel: l.homeNotificationsSemantics(feed.unreadCount),
            background: p.sf,
            shadow: true,
            badge: feed.unreadCount > 0,
            onPressed: () => context.push(Routes.notifications),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String? initials;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: context.l10n.homeProfileSemantics,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.go(Routes.profile),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.yelS,
            shape: BoxShape.circle,
            border: Border.all(color: p.yel, width: 2),
          ),
          child: initials == null || initials!.isEmpty
              ? AppIcon(AppIcons.user, size: 22, color: p.ink)
              : Text(initials!, style: AppTypography.display(18, color: p.ink, height: 1)),
        ),
      ),
    );
  }
}

/// "Fırsat, etkinlik, yer ara…" — dokununca Arama ekranı açılır. Kolay Mod: 56 px.
class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hint = context.l10n.homeSearchHint;
    final h = context.easyMode ? 56.0 : 48.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Semantics(
        button: true,
        label: hint,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => context.push(Routes.search),
          child: Container(
            height: h,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(h / 2), boxShadow: p.cardShadow),
            child: Row(
              children: [
                AppIcon(AppIcons.search, size: 20, color: p.mut),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(15, weight: FontWeight.w600, color: p.mut),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

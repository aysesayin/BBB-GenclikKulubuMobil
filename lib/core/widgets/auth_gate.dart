import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/app/app_config.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/l10n.dart';
import '../router/routes.dart';
import '../session/session_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_button.dart';
import 'app_icon.dart';
import 'app_icons.dart';
import 'app_sheet.dart';
import 'mascot.dart';

/// Misafir modu "yumuşak duvarı" (S2). İçerik görünür kalır; aksiyonda bu sheet açılır.
///
/// ```dart
/// onPressed: () => AuthGate.guard(context, () => vm.claim())
/// ```
abstract final class AuthGate {
  /// Kullanıcı üyeyse [action]'ı çalıştırır, değilse sheet'i gösterir.
  static Future<void> guard(BuildContext context, VoidCallback action, {String? title}) async {
    if (context.read<SessionController>().isAuthenticated) {
      action();
      return;
    }
    await show(context, title: title);
  }

  static Future<void> show(BuildContext context, {String? title}) =>
      AppSheet.show<void>(context, builder: (ctx) => _AuthGateBody(title: title));
}

class _AuthGateBody extends StatelessWidget {
  const _AuthGateBody({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    // Sağlayıcı yoksa (izole widget testleri) yapılandırma varsayılanı kullanılır.
    final bonus = Fmt.number((context.read<AppRepository?>()?.current ?? const AppConfig()).welcomeBonus);
    final perks = [(l.guestPerkCodes, p.tile1), (l.guestPerkBuan, p.tile4), (l.guestPerkApply, p.tile2)];
    void go(String route) {
      Navigator.of(context).pop();
      GoRouter.of(context).push(route);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Mascot(size: 76),
            const SizedBox(width: 14),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title ?? l.guestTitle, style: AppTypography.display(26, height: 1.05, color: p.ink)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(l.guestMessage, style: AppTypography.body(15, color: p.mut, height: 1.4)),
        const SizedBox(height: 14),
        for (final (text, color) in perks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: AppIcon(AppIcons.check, size: 16, color: p.onTile, strokeWidth: 2.8),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink))),
              ],
            ),
          ),
        const SizedBox(height: 8),
        AppButton(label: l.guestRegister(bonus), onPressed: () => go(Routes.interests)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: AppButton(label: l.guestLogin, onPressed: () => go(Routes.login), variant: AppButtonVariant.outlineLine, size: AppButtonSize.medium)),
            const SizedBox(width: 8),
            Expanded(child: AppButton.text(label: l.guestKeepBrowsing, onPressed: () => Navigator.of(context).pop())),
          ],
        ),
      ],
    );
  }
}

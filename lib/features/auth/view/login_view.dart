import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../l10n/l10n.dart';
import '../../onboarding/widgets/motion.dart';
import '../../onboarding/widgets/nav_x.dart';
import '../../onboarding/widgets/poster_title.dart';
import '../biometric_authenticator.dart';
import '../view_model/login_view_model.dart';
import '../widgets/login_form.dart';

/// A6 · Giriş yap: üst %45 morflanan blob'lar + kinetik başlık, alttan kayan form.
/// Kolay Mod: blob ve kinetik başlık yerine düz başlık, 56 px dokunma hedefleri.
class LoginView extends StatelessWidget {
  const LoginView({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => LoginViewModel(sl<AuthRepository>(), sl<SessionController>(), sl<BiometricAuthenticator>(), from: from)..init(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final reduce = context.reduceMotion;
    final easy = context.easyMode;
    void done() {
      final dest = context.read<LoginViewModel>().destination ?? Routes.home;
      context.go(dest);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: p.heroGradient),
        child: Stack(
          children: [
            if (!easy) ...[
              Positioned(left: -80, top: -60, child: MorphBlob(size: 280, color: p.blob, opacity: .85, period: const Duration(seconds: 9))),
              Positioned(right: -90, top: 90, child: MorphBlob(size: 240, color: p.mint, opacity: .85, seed: 3, period: const Duration(seconds: 11))),
              Positioned(left: 120, top: 230, child: MorphBlob(size: 160, color: p.sky, opacity: .8, seed: 6, period: const Duration(seconds: 7))),
            ],
            Positioned.fill(child: ColoredBox(color: p.night.withValues(alpha: p.isDark ? .42 : .4))),
            Positioned(
              top: mq.padding.top + 4,
              left: 8,
              child: AppIconButton(
                icon: AppIcons.back,
                semanticLabel: l.commonBack,
                color: p.onNight,
                iconSize: 24,
                size: context.touchTarget,
                onPressed: () => context.popOr(Routes.welcome),
              ),
            ),
            Positioned(
              left: 24,
              right: 16,
              top: mq.padding.top + 68,
              child: easy
                  ? Semantics(header: true, child: Text(l.authLoginEasyTitle, style: AppTypography.display(36, color: p.onNight)))
                  : PosterTitle(lines: [l.authLoginLine1, l.authLoginLine2], size: 80, color: p.onNight, highlight: p.onNight, from: const Offset(60, 0), stagger: const Duration(milliseconds: 120)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboard,
              child: _SheetIn(
                reduce: reduce,
                child: Semantics(
                  container: true,
                  label: l.authLoginForm,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: mq.size.height - keyboard - mq.padding.top - 56),
                    decoration: BoxDecoration(
                      color: p.sf,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: p.night.withValues(alpha: .18), blurRadius: 40, offset: const Offset(0, -12))],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 34 + (keyboard > 0 ? 0 : mq.padding.bottom)),
                      child: LoginForm(onSuccess: done),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Form sayfası 600 ms (150 ms gecikmeli) alttan kayar; hareketi azalt → fade.
class _SheetIn extends StatelessWidget {
  const _SheetIn({required this.reduce, required this.child});

  final bool reduce;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: reduce ? 400 : 750),
        child: child,
        builder: (_, v, child) {
          if (reduce) return Opacity(opacity: v, child: child);
          final t = onbCurve.transform(((v * 750 - 150) / 600).clamp(0.0, 1.0));
          return FractionalTranslation(translation: Offset(0, 1.1 * (1 - t)), child: child);
        },
      );
}

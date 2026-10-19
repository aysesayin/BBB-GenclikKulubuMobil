import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/welcome_view_model.dart';
import '../widgets/poster_title.dart';
import '../widgets/welcome_parts.dart';

/// A3 · Karşılama / karar ekranı.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => WelcomeViewModel(sl<SessionController>(), sl<AppRepository>(), from: from),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.read<WelcomeViewModel>();
    final pad = MediaQuery.paddingOf(context);
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned(left: 0, right: 0, top: pad.top - 8, child: WelcomeMarquee(tags: l.onbWelcomeTags.split('|'))),
          Positioned(
            left: 0,
            right: 0,
            top: h * .39,
            height: 140,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.bg.withValues(alpha: 0), p.bg],
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, top: h * .39 + 139, bottom: 0, child: ColoredBox(color: p.bg)),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 40 + pad.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  PosterTitle(
                    lines: [l.onbWelcomeLine1, l.onbWelcomeLine2],
                    size: 92,
                    highlight: p.teal,
                    from: const Offset(0, 40),
                    stagger: const Duration(milliseconds: 120),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: WelcomeBonusPill(label: l.onbWelcomeBonus(Fmt.number(vm.bonus))),
                  ),
                  const SizedBox(height: 28),
                  BreathingCta(label: l.onbWelcomeStart, onPressed: () => context.push(Routes.interests)),
                  const SizedBox(height: 10),
                  AppButton(
                    label: l.onbWelcomeLogin,
                    variant: AppButtonVariant.outlineInk,
                    onPressed: () => context.push(vm.loginRoute),
                  ),
                  const SizedBox(height: 10),
                  _GuestLink(
                    label: l.onbWelcomeGuest,
                    onTap: () async {
                      final route = await vm.continueAsGuest();
                      if (context.mounted) context.go(route);
                    },
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

class _GuestLink extends StatelessWidget {
  const _GuestLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.palette.ink;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: Text(
              label,
              style: AppTypography.body(15, weight: FontWeight.w800, color: ink).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

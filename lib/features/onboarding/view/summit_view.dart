import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/summit_view_model.dart';
import '../widgets/poster_title.dart';
import '../widgets/summit_card.dart';
import '../widgets/summit_fx.dart';
import '../widgets/tilt.dart';

/// A7 · Zirve / kart doğuşu (≈ 4,5 sn). Hareketi azalt → kart doğrudan arka yüzde.
class SummitView extends StatelessWidget {
  const SummitView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => SummitViewModel(sl<AuthRepository>(), sl<AppRepository>(), sl<SessionController>()),
        child: const _Body(),
      );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SingleTickerProviderStateMixin {
  static const _len = 4.5;
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));
  final _cues = HapticCues.summit();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() => _cues.at(_c.value * _len));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play();
  }

  void _play() {
    _cues.reset();
    if (context.reduceMotion) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<SummitViewModel>();
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: p.night,
      body: TiltBuilder(
        builder: (context, tilt, _) => AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final s = _c.value * _len;
            final spot = summitSeg(s, .5, 1.3);
            final fall = summitSeg(s, .5, 1.55);
            final flip = summitSeg(s, 2.0, 2.9);
            final settle = summitSeg(s, 3.1, 3.8);
            final rain = s >= 3.1;
            final title = summitSeg(s, .5, 1.1);
            final rotZ = (-28 + 24 * fall) * (1 - flip) * 3.1416 / 180;
            return Stack(
              children: [
                Positioned(
                  left: -100,
                  right: -100,
                  top: 40,
                  height: 520,
                  child: Opacity(
                    opacity: spot,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -.2),
                          radius: .62,
                          colors: [p.buanFill.withValues(alpha: .53), p.night.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
                if (rain) const Positioned.fill(child: CoinRain()),
                Positioned(
                  top: pad.top + 4,
                  right: 12,
                  child: AppIconButton(
                    icon: 'M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5',
                    semanticLabel: l.onbSummitReplay,
                    background: p.onNight.withValues(alpha: .1),
                    color: p.onNight,
                    iconSize: 20,
                    onPressed: () {
                      vm.replay();
                      _play();
                    },
                  ),
                ),
                if (s >= .5)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: pad.top + 48,
                    child: Opacity(
                      opacity: title,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - title)),
                        child: Transform.scale(
                          scale: .9 + .1 * title,
                          child: PosterTitle(lines: [l.onbSummitTitle], size: 64, color: p.glow, align: CrossAxisAlignment.center, animate: false),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: pad.top + 202 - 70 * settle,
                  child: Center(
                    child: Opacity(
                      opacity: summitSeg(s, .5, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, -720 * (1 - fall)),
                        child: Transform.rotate(
                          angle: rotZ,
                          child: Transform.scale(
                            scale: 1 - .1 * settle,
                            child: SummitCard(
                              flip: flip,
                              tilt: tilt.dx,
                              name: vm.fullName,
                              memberNo: vm.memberNo,
                              level: vm.levelName,
                              qrData: vm.qrData,
                              checkInCode: vm.checkInCode,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (rain) ...[
                  Positioned(left: 24, right: 24, top: pad.top + 338, child: _Total(vm: vm, t: summitSeg(s, 3.1, 4.5, Curves.easeOutExpo), fade: settle)),
                  Positioned(left: 24, right: 24, bottom: 36 + pad.bottom, child: Opacity(opacity: summitSeg(s, 3.5, 4.0), child: _Ctas(vm: vm))),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.vm, required this.t, required this.fade});

  final SummitViewModel vm;
  final double t, fade;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final caption = AppTypography.body(14, weight: FontWeight.w900, color: p.onNight.withValues(alpha: .9));
    return Semantics(
      liveRegion: true,
      label: '${l.buanAmount(Fmt.number(vm.total))} · ${l.onbSummitInWallet}',
      excludeSemantics: true,
      child: Opacity(
        opacity: fade,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - fade)),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (vm.onboardingBonus > 0) ...[
                    Text(l.onbSummitOnboarding(Fmt.number(vm.onboardingBonus)), style: caption),
                    Text('+', style: caption),
                  ],
                  Text(l.onbSummitWelcome(Fmt.number(vm.welcomeBonus)), style: caption),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                Fmt.number((vm.total * t).round()),
                style: AppTypography.display(84, height: 1, color: p.glow).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              Text(l.onbSummitInWallet, style: AppTypography.display(22, color: p.onNight)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ctas extends StatelessWidget {
  const _Ctas({required this.vm});

  final SummitViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            // TODO(varsayım): Apple/Google Wallet pass üretimi backend + paket gerektirir; şimdilik bilgi mesajı.
            Haptics.light();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.onbSummitWalletSoon)));
          },
          icon: AppIcon(AppIcons.wallet, size: 20, color: p.onNight),
          label: Text(l.onbSummitAddWallet, style: AppTypography.buttonM.copyWith(color: p.onNight)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            side: BorderSide(color: p.onNight.withValues(alpha: .4), width: 2),
          ),
        ),
        const SizedBox(height: 10),
        AppButton.buan(
          label: vm.inviteReward > 0 ? l.onbSummitInvite(Fmt.signed(vm.inviteReward)) : l.onbSummitInviteShort,
          size: AppButtonSize.medium,
          onPressed: () => context.push(Routes.invite),
        ),
        const SizedBox(height: 10),
        AppButton(label: l.onbSummitStart, onPressed: () => context.go(Routes.prePermission)),
        const SizedBox(height: 10),
        Text(
          l.onbSummitProfileNote,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body(13, weight: FontWeight.w800, color: p.onNight.withValues(alpha: .8)),
        ),
      ],
    );
  }
}

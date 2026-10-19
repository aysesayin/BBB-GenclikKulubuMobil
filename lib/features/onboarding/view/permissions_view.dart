import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../permission_gateway.dart';
import '../view_model/permissions_view_model.dart';
import '../widgets/motion.dart';
import '../widgets/permission_card.dart';
import '../widgets/poster_title.dart';

/// A8 · İzinler — kart destesi. Kaydır ya da butonla fırlat; bitince "Hazırsın!".
class PermissionsView extends StatelessWidget {
  const PermissionsView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => PermissionsViewModel(sl<PermissionGateway>(), sl<SessionController>()),
        child: const _Body(),
      );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  double _drag = 0;

  void _end(PermissionsViewModel vm, DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_drag > 100 || v > 800) {
      Haptics.selection();
      vm.allow();
    } else if (_drag < -100 || v < -800) {
      Haptics.selection();
      vm.skip();
    }
    setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<PermissionsViewModel>();
    final pad = MediaQuery.paddingOf(context);
    final total = PermissionsViewModel.cards.length;
    return Scaffold(
      backgroundColor: p.bg,
      body: Padding(
        padding: EdgeInsets.fromLTRB(24, pad.top + 4, 24, 40 + pad.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: PosterTitle(lines: [l.onbPermTitle], size: 34, lineHeight: 1, animate: false)),
                const SizedBox(width: 8),
                Text(l.onbPermProgress(vm.done ? total : vm.current + 1, total), style: AppTypography.number(14, color: p.ink)),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.onbPermSubtitle, style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink.withValues(alpha: .85))),
            const SizedBox(height: 24),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = PermissionsViewModel.cards.length - 1; i >= 0; i--) _card(vm, i),
                  if (vm.done) Positioned.fill(child: _Done(granted: vm.granted)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 58,
              child: vm.done
                  ? AppButton(
                      label: l.onbPermGo,
                      onPressed: () async {
                        final route = await vm.finish();
                        if (context.mounted) context.go(route);
                      },
                    )
                  : _Dots(current: vm.current, total: total),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(PermissionsViewModel vm, int i) {
    final kind = PermissionsViewModel.cards[i];
    final out = vm.flungRight(kind);
    final depth = (i - vm.current).toDouble();
    final top = out == null && depth == 0;
    final reduce = context.reduceMotion;
    Matrix4 m;
    var op = 1.0;
    if (out != null) {
      final s = out ? 1 : -1;
      m = Matrix4.translationValues(520.0 * s, 0, 0)..rotateZ(24 * s * math.pi / 180);
      op = 0;
    } else if (top) {
      m = Matrix4.translationValues(_drag, 0, 0)..rotateZ(_drag / 520 * 24 * math.pi / 180);
    } else {
      final r = depth.toInt().isOdd ? 3.0 : -3.0;
      m = Matrix4.translationValues(0, depth * 16, 0)
        ..multiply(Matrix4.diagonal3Values(1 - depth * .05, 1 - depth * .05, 1))
        ..rotateZ(r * math.pi / 180);
    }
    final card = PermissionCard(
      kind: kind,
      interactive: top && !vm.busy,
      onAllow: () {
        Haptics.selection();
        vm.allow();
      },
      onSkip: () {
        Haptics.selection();
        vm.skip();
      },
    );
    return Positioned.fill(
      child: ExcludeSemantics(
        excluding: !top,
        child: AnimatedContainer(
          duration: _drag != 0 && top ? Duration.zero : Duration(milliseconds: reduce ? 200 : 500),
          curve: onbCurve,
          transform: m,
          transformAlignment: Alignment.center,
          child: AnimatedOpacity(
            opacity: op,
            duration: Duration(milliseconds: reduce ? 200 : 500),
            child: top
                ? GestureDetector(
                    onHorizontalDragUpdate: (d) => setState(() => _drag += d.delta.dx),
                    onHorizontalDragEnd: (d) => _end(vm, d),
                    child: card,
                  )
                : IgnorePointer(child: card),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.current, required this.total});

  final int current, total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i < current ? p.cta : (i == current ? p.cta : (p.isDark ? p.onNight.withValues(alpha: .3) : p.line)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.granted});

  final int granted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: context.reduceMotion ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (_, v, child) {
          final s = v < .7 ? .7 + .36 * (v / .7) : 1.06 - .06 * ((v - .7) / .3);
          return Opacity(opacity: (v / .7).clamp(0, 1), child: Transform.scale(scale: s, child: child));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Mascot(mood: MascotMood.celebrate, size: 120),
            const SizedBox(height: 14),
            PosterTitle(lines: [l.onbPermDone], size: 56, lineHeight: 1, align: CrossAxisAlignment.center, animate: false),
            const SizedBox(height: 14),
            Text(
              l.onbPermSummary(granted),
              textAlign: TextAlign.center,
              style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink.withValues(alpha: .9)),
            ),
          ],
        ),
      ),
    );
  }
}

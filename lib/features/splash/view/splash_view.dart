import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/splash_view_model.dart';
import '../widgets/splash_scene.dart';

/// A1 · Animasyonlu açılış (2,2 sn, tek seferlik). Dokununca animasyon atlanır.
/// Hareketi azalt → son kare + 400 ms fade.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => SplashViewModel(sl<SessionController>(), sl<AppRepository>())..start(),
        child: const _Body(),
      );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late final SplashViewModel _vm = context.read<SplashViewModel>();
  bool _reduce = false, _started = false, _navigated = false;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_maybeGo);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _maybeGo();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduce = context.reduceMotion;
    if (_reduce) {
      _c.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGo());
    } else {
      Haptics.light();
      _c.forward();
    }
  }

  void _skip() {
    if (_c.isAnimating) _c.value = 1;
  }

  void _maybeGo() {
    final dest = _vm.destination;
    if (_navigated || !mounted || _vm.phase != SplashPhase.ready || dest == null || _c.value < 1) return;
    _navigated = true;
    context.go(dest);
  }

  @override
  void dispose() {
    _vm.removeListener(_maybeGo);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final phase = context.select<SplashViewModel, SplashPhase>((v) => v.phase);
    return Scaffold(
      backgroundColor: p.bg,
      body: phase == SplashPhase.maintenance
          ? const _Maintenance()
          : Semantics(
              button: true,
              label: context.l10n.onbSplashSkip,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _skip,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: _reduce ? 0 : 1, end: 1),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (_, o, child) => Opacity(opacity: o, child: child),
                  child: SizedBox.expand(child: SplashScene(t: _c)),
                ),
              ),
            ),
    );
  }
}

class _Maintenance extends StatelessWidget {
  const _Maintenance();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<SplashViewModel>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [Blob(shape: BlobShape.f, color: p.mint, width: 280), const Mascot(mood: MascotMood.sleepy, size: 180, motion: MascotMotion.float)],
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(l.onbMaintenanceTitle, textAlign: TextAlign.center, style: AppTypography.display(28, color: p.ink)),
            ),
            const SizedBox(height: 10),
            Text(
              vm.maintenanceMessage ?? l.errorMaintenance,
              textAlign: TextAlign.center,
              style: AppTypography.body(15, color: p.mut, height: 1.4),
            ),
            const SizedBox(height: 32),
            AppButton(label: l.commonRetry, busy: vm.phase == SplashPhase.loading, onPressed: vm.start),
          ],
        ),
      ),
    );
  }
}

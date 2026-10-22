import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/story_view_model.dart';
import '../widgets/motion.dart';
import '../widgets/poster_title.dart';
import '../widgets/story_chrome.dart';
import '../widgets/story_city_scene.dart';
import '../widgets/story_coin_scene.dart';
import '../widgets/tilt.dart';

/// A2 · Hikâye onboarding (2 × 6 sn: şehir → coin). İlk hikâyede "Hemen Başla" kısayolu.
class StoryView extends StatelessWidget {
  const StoryView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => StoryViewModel(sl<AuthRepository>(), sl<AppRepository>()), child: const _Body());
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: StoryViewModel.segment);
  late final StoryViewModel _vm = context.read<StoryViewModel>();
  int _shown = -1;

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener((s) {
      // Hareketi azalt: otomatik ilerleme yok (çubuk dolu gösterilir).
      if (s == AnimationStatus.completed && mounted && !context.reduceMotion) _vm.onSegmentDone();
    });
    _vm.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  /// Segment değişince çubuğu baştan başlatır; duraklatma çubuğu durdurur.
  void _sync() {
    if (!mounted) return;
    if (context.reduceMotion) {
      _progress.value = 1;
      return;
    }
    if (_vm.index != _shown) {
      _shown = _vm.index;
      _progress.forward(from: 0);
    }
    if (_vm.paused) {
      _progress.stop();
    } else if (!_progress.isAnimating && !_progress.isCompleted) {
      _progress.forward();
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_sync);
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<StoryViewModel>();
    final i = vm.index;
    final top = MediaQuery.paddingOf(context).top;
    final (Color ink, Color hl, Color blobA, Color blobB) = switch (i) {
      0 => (p.ink, p.teal, p.mint, p.sky),
      _ => (p.onBuan, p.onBuan, p.glow, p.coinMark),
    };
    final lines = [
      (l.onbStoryEyebrow1, l.onbStory1Line1, l.onbStory1Line2, l.onbStory1Sub),
      (l.onbStoryEyebrow2, l.onbStory2Line1, l.onbStory2Line2, l.onbStory2Sub),
    ][i];
    final track = i == 1 ? p.onBuan.withValues(alpha: .35) : ink.withValues(alpha: p.isDark ? .28 : .18);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(color: i == 0 ? p.bg : null, gradient: i == 1 ? p.buanGradient : null),
        child: TiltBuilder(
          builder: (context, tilt, _) => Stack(
            children: [
              Positioned(
                right: -120,
                top: 120,
                child: Transform.translate(
                  offset: Offset(tilt.dx * -14, tilt.dy * -10),
                  child: MorphBlob(size: 320, color: blobA, opacity: .55),
                ),
              ),
              Positioned(
                left: -140,
                bottom: 60,
                child: MorphBlob(size: 300, color: blobB, opacity: .5, seed: 4, period: const Duration(seconds: 12)),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: top + 4,
                child: StoryBars(count: StoryViewModel.count, index: i, progress: _progress, color: ink, track: track),
              ),
              Positioned(
                left: 16,
                right: 8,
                top: top + 14,
                child: _Header(eyebrow: lines.$1, ink: ink, paused: vm.paused),
              ),
              Positioned(
                left: 22,
                right: 10,
                top: top + 76,
                child: PosterTitle(key: ValueKey('t$i'), lines: [lines.$2, lines.$3], size: 104, color: ink, highlight: hl),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: top + 300,
                child: _Sub(key: ValueKey('s$i'), text: lines.$4, color: ink),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: top + 58,
                height: 300,
                child: StoryTapZones(
                  onPrev: vm.prev,
                  onNext: vm.next,
                  onPause: (v) => vm.setPaused(value: v),
                ),
              ),
              Positioned(left: 0, right: 0, top: top + 388, bottom: 0, child: _scene(vm, Offset(tilt.dx * 8, tilt.dy * 6))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scene(StoryViewModel vm, Offset parallax) {
    final l = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return switch (vm.index) {
      // Harita kartı küçük ekranlarda ölçeklenir; "Hemen Başla" her zaman görünür.
      0 => LayoutBuilder(
        builder: (_, c) => Column(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: c.maxWidth - 40,
                  height: 330,
                  child: Transform.translate(offset: parallax, child: StoryCityScene(bonusPin: vm.bonus)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 40 + bottom),
              child: AppButton(label: l.onbStoryStartNow, onPressed: () => context.go(Routes.welcome)),
            ),
          ],
        ),
      ),
      _ => Column(
        children: [
          Expanded(
            child: Center(
              child: StoryCoinScene(
                popped: vm.coinPopped,
                bonus: vm.bonus,
                parallax: parallax,
                onPop: () {
                  Haptics.medium();
                  vm.popCoin();
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 40 + bottom),
            child: vm.canFinish
                ? AppButton(label: l.commonContinue, onPressed: () => context.go(Routes.welcome))
                : _LockedCta(label: l.onbCoinFirst),
          ),
        ],
      ),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.eyebrow, required this.ink, required this.paused});

  final String eyebrow;
  final Color ink;
  final bool paused;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          eyebrow,
          style: AppTypography.body(13, weight: FontWeight.w900, color: ink.withValues(alpha: .9)),
        ),
      ),
      if (paused) const PausedChip(),
      TextButton(
        onPressed: () => context.go(Routes.welcome),
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: ink,
        ),
        child: Text(
          context.l10n.commonSkip,
          style: AppTypography.body(15, weight: FontWeight.w900, color: ink),
        ),
      ),
    ],
  );
}

class _Sub extends StatelessWidget {
  const _Sub({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: context.reduceMotion ? 400 : 850),
    builder: (_, v, child) => Opacity(opacity: context.reduceMotion ? v : ((v - .41) / .59).clamp(0, 1), child: child),
    child: Text(
      text,
      style: AppTypography.body(17, weight: FontWeight.w800, height: 1.4, color: color),
    ),
  );
}

class _LockedCta extends StatelessWidget {
  const _LockedCta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      enabled: false,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.onBuan.withValues(alpha: .22), borderRadius: BorderRadius.circular(28)),
        child: Text(label, style: AppTypography.buttonL.copyWith(color: p.onBuan)),
      ),
    );
  }
}

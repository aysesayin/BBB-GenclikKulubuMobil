import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/view_state.dart';
import '../../../core/di/locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/story_repository.dart';
import '../../../l10n/l10n.dart';
import '../../home/home_links.dart';
import '../view_model/story_view_model.dart';
import '../widgets/story_widgets.dart';

/// B4 · Hikâye (`/hikaye/:id`): 6 sn/segment, basılı tut = duraklat,
/// sola/sağa dokun = geri/ileri, aşağı kaydır = kapat.
class StoryView extends StatelessWidget {
  const StoryView({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => StoryViewModel(sl<StoryRepository>(), storyId)..load(), child: const _Player());
}

class _Player extends StatefulWidget {
  const _Player();

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: StoryViewModel.segmentDuration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _vm.next();
    });
  late final StoryViewModel _vm = context.read<StoryViewModel>()..addListener(_onVm);
  int _generation = -1;
  bool _closed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(restart: false);
  }

  void _onVm() => _sync(restart: _vm.generation != _generation);

  /// VM durumunu ilerleme animasyonuna uygular.
  void _sync({required bool restart}) {
    if (!mounted) return;
    if (_vm.finished || _vm.state is ViewEmpty) return _close();
    if (_vm.state is! ViewSuccess) return;
    final reduce = context.reduceMotion;
    if (restart || _generation == -1) {
      _generation = _vm.generation;
      _progress.value = reduce ? 1 : 0;
    }
    // "Hareketi azalt": otomatik ilerleme yok, segment dolu gösterilir; kullanıcı dokunarak geçer.
    // TODO(varsayım): Hareketi azalt açıkken otomatik geçiş kapatıldı (tasarımdaki CSS yalnız animasyonu kapatıyor).
    if (reduce || _vm.paused) {
      _progress.stop();
    } else if (!_progress.isAnimating) {
      _progress.forward();
    }
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _progress.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  /// CTA: hikâyeyi kapatıp hedefi açar (sekme kökü → go, diğerleri → push).
  void _openCta() {
    final link = _vm.current?.link;
    final target = link == null ? null : routeForLink(link);
    if (target == null) return;
    Haptics.light();
    _closed = true;
    _progress.stop();
    final router = GoRouter.of(context)..pop();
    if (isTabRoot(target)) {
      router.go(target);
    } else {
      router.push(target);
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<StoryViewModel>();
    final slide = vm.current;
    final pad = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.night,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (_) => vm.setPaused(value: true),
          onLongPressEnd: (_) => vm.setPaused(value: false),
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 300) Navigator.of(context).maybePop();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (slide != null) StoryBackdrop(key: ValueKey(slide.id), slide: slide),
              if (vm.state case ViewError(:final error))
                ErrorStateView(error: error, onRetry: vm.refresh)
              else if (slide == null)
                Center(child: CircularProgressIndicator(color: p.paper)),
              if (slide != null)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _TapZone(label: l.storyPrev, onTap: vm.previous),
                    ),
                    Expanded(
                      flex: 7,
                      child: _TapZone(label: l.storyNext, onTap: vm.next),
                    ),
                  ],
                ),
              Positioned(
                top: pad.top + 6,
                left: 12,
                right: 12,
                child: vm.count == 0 ? const SizedBox.shrink() : StorySegments(count: vm.count, index: vm.index, progress: _progress),
              ),
              Positioned(
                top: pad.top + 18,
                left: 16,
                right: 8,
                child: _Header(vm: vm),
              ),
              if (slide != null)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 44 + pad.bottom,
                  child: StoryCaption(slide: slide, onCta: slide.link == null ? null : _openCta),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapZone extends StatelessWidget {
  const _TapZone({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.vm});

  final StoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final story = vm.state.dataOrNull;
    final age = vm.ageAt(DateTime.now());
    final ago = age.inHours < 1
        ? l.storyAgoMinutes(age.inMinutes)
        : age.inDays < 1
        ? l.storyAgoHours(age.inHours)
        : l.storyAgoDays(age.inDays);
    return Row(
      children: [
        if (story != null) ...[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.paper, shape: BoxShape.circle),
            child: Text(story.authorInitials, style: AppTypography.display(14, color: p.isDark ? p.buanFill : p.teal, height: 1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: story.author),
                  TextSpan(
                    text: ' · $ago',
                    style: TextStyle(fontWeight: FontWeight.w600, color: p.paper.withValues(alpha: .85)),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(14, weight: FontWeight.w800, color: p.paper),
            ),
          ),
        ] else
          const Spacer(),
        AppIconButton(
          icon: AppIcons.close,
          semanticLabel: l.storyClose,
          color: p.paper,
          iconSize: 24,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

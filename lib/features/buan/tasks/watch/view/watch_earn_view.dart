import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../../core/base/base_view.dart';
import '../../../../../core/di/locator.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/watch_video.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';
import '../../../../../l10n/l10n.dart';
import '../../widgets/task_dates.dart';
import '../view_model/watch_earn_view_model.dart';
import '../widgets/up_next_list.dart';
import '../widgets/video_stage.dart';

/// E8 · İzle Kazan.
class WatchEarnView extends StatelessWidget {
  const WatchEarnView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => WatchEarnViewModel(sl<WatchEarnRepository>())..load(), child: const _Body());
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with WidgetsBindingObserver {
  late final WatchEarnViewModel _vm = context.read<WatchEarnViewModel>();
  YoutubePlayerController? _player;
  final _subs = <StreamSubscription<Object?>>[];
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm.addListener(_onVm);
  }

  void _onVm() {
    if (!mounted) return;
    final c = _vm.completion;
    if (c != null && !_celebrate) {
      setState(() => _celebrate = true);
      if (c.awarded > 0) showRewardToast(context, label: context.l10n.taskWatchToast, amount: c.awarded);
    }
    final e = _vm.error;
    if (e != null) {
      _vm.clearError();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessageOf(context, e))));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fg = state == AppLifecycleState.resumed;
    if (!fg) _player?.pauseVideo();
    _vm.setForeground(fg);
  }

  void _toggle(WatchVideo v) {
    final c = _player;
    if (c == null) {
      final player = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          enableKeyboard: false,
          pointerEvents: PointerEvents.none,
          strictRelatedVideos: true,
          showVideoAnnotations: false,
          interfaceLanguage: 'tr',
          captionLanguage: 'tr',
          videoStateUpdateInterval: 500,
        ),
      );
      _subs
        ..add(
          player.videoStateStream.listen((s) {
            final back = _vm.onPosition(s.position.inMilliseconds / 1000);
            if (back != null) player.seekTo(seconds: back, allowSeekAhead: true);
          }),
        )
        ..add(player.stream.listen((value) => _vm.setPlaying(value.playerState == PlayerState.playing)));
      player.loadVideoById(videoId: v.youtubeId, startSeconds: _vm.watchedSec);
      setState(() => _player = player);
      return;
    }
    _vm.playing ? c.pauseVideo() : c.playVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vm.removeListener(_onVm);
    for (final s in _subs) {
      s.cancel();
    }
    _player?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WatchEarnViewModel>();
    final l = context.l10n;
    return Scaffold(
      body: Stack(
        children: [
          ViewStateBuilder<WatchVideo>(
            state: vm.state,
            onRetry: vm.load,
            skeleton: (_) => const _Skeleton(),
            builder: (context, v, {required offline}) => ListView(
              padding: EdgeInsets.only(bottom: 40 + MediaQuery.paddingOf(context).bottom),
              children: [
                AppBackHeader(
                  title: l.taskWatchTitle,
                  trailing: [BuanPointsBadge(points: v.reward, minWidth: 80, height: 32)],
                ),
                if (offline) const OfflineBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: VideoStage(
                    controller: _player,
                    playing: vm.playing,
                    positionSec: vm.positionSec,
                    durationSec: v.durationSec,
                    onToggle: () => _toggle(v),
                  ),
                ),
                _Info(video: v),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: WatchProgressCard(
                    progress: vm.progress,
                    reached: vm.thresholdReached || vm.done,
                    message: _message(l, vm, v),
                    rule: _rule(l, vm, v),
                  ),
                ),
                if (vm.completion case final c?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: WatchDoneBanner(label: l.taskWatchDoneBanner, amount: c.awarded),
                  ),
                if (v.upNext.isNotEmpty) UpNextList(items: v.upNext),
              ],
            ),
          ),
          Positioned.fill(child: CelebrationOverlay(play: _celebrate, coins: true)),
        ],
      ),
    );
  }

  String _message(AppLocalizations l, WatchEarnViewModel vm, WatchVideo v) {
    if (vm.done && vm.completion == null) return l.taskWatchAlreadyDone;
    return vm.thresholdReached || vm.done ? l.taskWatchWon : l.taskWatchKeepGoing;
  }

  String _rule(AppLocalizations l, WatchEarnViewModel vm, WatchVideo v) {
    final next = vm.completion?.nextAvailableAt ?? v.nextAvailableAt;
    if (vm.done && next != null) return l.taskWatchNextIn(daysUntil(next));
    return l.taskWatchRule((v.completeRatio * 100).round());
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.video});

  final WatchVideo video;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (video.source.isNotEmpty)
            Text(
              trUpper(video.source),
              style: AppTypography.body(12, weight: FontWeight.w900, color: p.mut).copyWith(letterSpacing: .5),
            ),
          const SizedBox(height: 6),
          Semantics(
            header: true,
            child: Text(video.title, style: AppTypography.display(22, height: 1.15, color: p.ink)),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 64, 20, 0),
      children: const [
        AspectRatio(aspectRatio: 353 / 199, child: SkeletonBox(radius: 24)),
        SizedBox(height: 16),
        SkeletonBox(width: 160, height: 12),
        SizedBox(height: 8),
        SkeletonBox(height: 24),
        SizedBox(height: 16),
        SkeletonBox(height: 108, radius: 22),
      ],
    ),
  );
}

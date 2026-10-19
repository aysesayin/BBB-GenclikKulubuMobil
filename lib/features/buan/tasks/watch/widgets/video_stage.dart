import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../l10n/l10n.dart';
import '../../widgets/task_icons.dart';

/// Video alanı (353×199, r24): başlamadan önce illüstrasyon, sonra YouTube
/// oynatıcı. Oynatıcı dokunmaya kapalıdır (ileri sarma yok); yalnız ortadaki
/// oynat/duraklat butonu çalışır.
class VideoStage extends StatelessWidget {
  const VideoStage({
    super.key,
    required this.controller,
    required this.playing,
    required this.positionSec,
    required this.durationSec,
    required this.onToggle,
  });

  final YoutubePlayerController? controller;
  final bool playing;
  final double positionSec;
  final int durationSec;
  final VoidCallback onToggle;

  String _clock(double sec) {
    final s = sec.round().clamp(0, 359999);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final c = controller;
    final fraction = durationSec <= 0 ? 0.0 : (positionSec / durationSec).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 353 / 199,
        child: ColoredBox(
          color: p.primary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (c == null)
                SvgArt(
                  '<svg viewBox="0 0 353 199"><path d="M-10 199 L90 90 L160 150 L230 70 L363 199 Z" fill="${p.primary.hex}" opacity=".7"/>'
                  '<path d="M120 199 L230 110 L363 199 Z" fill="${p.secondary.hex}" opacity=".8"/>'
                  '<circle cx="290" cy="50" r="22" fill="${p.cta.hex}"/></svg>',
                  fit: BoxFit.cover,
                )
              else
                IgnorePointer(
                  child: YoutubePlayer(controller: c, backgroundColor: p.primary, enableFullScreenOnVerticalDrag: false),
                ),
              Center(
                child: Semantics(
                  button: true,
                  label: playing ? l.taskWatchPause : l.taskWatchPlay,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(color: p.paper.withValues(alpha: .95), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: AppIcon(
                        playing ? TaskIcons.pause : TaskIcons.play,
                        size: playing ? 26 : 28,
                        color: p.onTile,
                        fill: p.onTile,
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppProgressBar(value: fraction, height: 6, color: p.cta, track: p.paper.withValues(alpha: .3)),
              ),
              Positioned(
                left: 12,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: p.night.withValues(alpha: .55), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '${_clock(positionSec)} / ${_clock(durationSec.toDouble())}',
                    style: AppTypography.number(12, weight: FontWeight.w800, color: p.paper),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İzleme ilerleme kartı: 76 px halka + durum mesajı + kural.
class WatchProgressCard extends StatelessWidget {
  const WatchProgressCard({super.key, required this.progress, required this.reached, required this.message, required this.rule});

  final double progress;
  final bool reached;
  final String message, rule;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct = (progress * 100).round();
    return AppCard(
      child: Row(
        children: [
          ProgressRing(
            value: progress,
            size: 76,
            stroke: 8,
            color: reached ? p.secondary : p.primary,
            child: Text('%$pct', style: AppTypography.number(18, color: p.ink)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
                  ),
                ),
                const SizedBox(height: 4),
                Text(rule, style: AppTypography.body(13, color: p.mut)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Tebrikler, video tamam!  +1.000" mor şerit (pop girişli).
class WatchDoneBanner extends StatelessWidget {
  const WatchDoneBanner({super.key, required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: context.reduceMotion ? 1 : .6, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: const Cubic(.34, 1.56, .64, 1),
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(color: p.buanFill, borderRadius: BorderRadius.circular(24)),
          child: Row(
            children: [
              SvgArt(
                '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="11" fill="${p.paper.hex}"/><circle cx="12" cy="12" r="9" fill="${p.buanFill.hex}"/>'
                '<path d="M9.8 8l6.4 4-6.4 4z" fill="${p.glow.hex}"/></svg>',
                width: 48,
                height: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body(16, weight: FontWeight.w900, color: p.onBuan),
                ),
              ),
              Text(Fmt.signed(amount), maxLines: 1, style: AppTypography.number(22, color: p.glow)),
            ],
          ),
        ),
      ),
    );
  }
}

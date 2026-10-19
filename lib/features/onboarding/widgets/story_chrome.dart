import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

/// Üstteki 3 segmentli ilerleme çubuğu (4 px, 4 px aralık).
class StoryBars extends StatelessWidget {
  const StoryBars({super.key, required this.count, required this.index, required this.progress, required this.color, required this.track});

  final int count, index;
  final Animation<double> progress;
  final Color color, track;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedBuilder(
          animation: progress,
          builder: (_, _) => Row(
            children: [
              for (var k = 0; k < count; k++) ...[
                if (k > 0) const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 4,
                      child: Stack(
                        children: [
                          Positioned.fill(child: ColoredBox(color: track)),
                          FractionallySizedBox(
                            widthFactor: k < index ? 1 : (k == index ? progress.value : 0),
                            child: ColoredBox(color: color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Sol (120 px) geri, sağ ileri dokunma bölgeleri; 300 ms basılı tutunca duraklatır.
class StoryTapZones extends StatefulWidget {
  const StoryTapZones({super.key, required this.onPrev, required this.onNext, required this.onPause});

  final VoidCallback onPrev, onNext;
  final ValueChanged<bool> onPause;

  @override
  State<StoryTapZones> createState() => _StoryTapZonesState();
}

class _StoryTapZonesState extends State<StoryTapZones> {
  Timer? _hold;
  bool _held = false;

  void _down() {
    _held = false;
    _hold?.cancel();
    _hold = Timer(const Duration(milliseconds: 300), () {
      _held = true;
      widget.onPause(true);
    });
  }

  void _up(VoidCallback tap) {
    _hold?.cancel();
    if (_held) {
      _held = false;
      widget.onPause(false);
    } else {
      tap();
    }
  }

  void _cancel() {
    _hold?.cancel();
    if (_held) widget.onPause(false);
    _held = false;
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  Widget _zone(String label, VoidCallback tap) => Semantics(
        button: true,
        label: label,
        onTap: tap,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _down(),
          onPointerUp: (_) => _up(tap),
          onPointerCancel: (_) => _cancel(),
          child: const SizedBox.expand(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        SizedBox(width: 120, child: _zone(l.onbStoryPrev, widget.onPrev)),
        Expanded(child: _zone(l.onbStoryNext, widget.onNext)),
      ],
    );
  }
}

/// "Duraklatıldı" çipi.
class PausedChip extends StatelessWidget {
  const PausedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(14)),
        child: Text(context.l10n.onbStoryPaused, style: AppTypography.body(12, weight: FontWeight.w900, color: p.onChip)),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../l10n/l10n.dart';
import '../view_model/quiz_view_model.dart';

/// Soru süresi çubuğu: 10 px, 100 % → 0 doğrusal. Bitince [onTimeUp].
/// [stopped] (cevaplandı) → boşalır ve durur.
class QuizTimerBar extends StatefulWidget {
  const QuizTimerBar({super.key, required this.seconds, required this.stopped, required this.onTimeUp});

  final int seconds;
  final bool stopped;
  final VoidCallback onTimeUp;

  @override
  State<QuizTimerBar> createState() => _QuizTimerBarState();
}

class _QuizTimerBarState extends State<QuizTimerBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        duration: Duration(seconds: widget.seconds),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed && !widget.stopped) widget.onTimeUp();
      });

  @override
  void initState() {
    super.initState();
    if (!widget.stopped) _c.forward();
  }

  @override
  void didUpdateWidget(QuizTimerBar old) {
    super.didUpdateWidget(old);
    if (widget.stopped && !old.stopped) _c.stop();
    if (!widget.stopped && old.stopped && !_c.isCompleted) _c.forward(); // gönderim hatası → süre devam
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: context.l10n.taskQuizTimerSemantics(widget.seconds),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => AppProgressBar(value: widget.stopped ? 0 : 1 - _c.value, height: 10, color: p.primary),
      ),
    );
  }
}

/// Cevap seçeneği (64 px, r20, 3 px çerçeve). Doğru → yeşil + ✓, yanlış → kırmızı + ✕.
class QuizOptionButton extends StatelessWidget {
  const QuizOptionButton({super.key, required this.label, required this.mark, required this.selected, required this.onTap});

  final String label;
  final OptionMark mark;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final (Color bg, Color border, Color fg) = switch (mark) {
      OptionMark.correct => (p.grnS, p.grnT, p.grnT),
      OptionMark.wrong => (p.errorSoft, p.errorText, p.errorText),
      OptionMark.idle => (p.sf2, selected ? p.ink : Colors.transparent, p.ink),
    };
    final size = label.length <= 6 ? 24.0 : (label.length <= 14 ? 18.0 : 15.0);
    final body = AnimatedContainer(
      duration: AppDurations.fast,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(size, height: 1.05, color: fg),
            ),
          ),
          if (mark != OptionMark.idle) ...[
            const SizedBox(width: 8),
            AppIcon(
              mark == OptionMark.correct ? AppIcons.check : AppIcons.close,
              size: 22,
              color: fg,
              strokeWidth: 3.4,
              semanticLabel: mark == OptionMark.correct ? l.taskQuizCorrect : l.taskQuizWrong,
            ),
          ],
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                Haptics.selection();
                onTap!();
              },
        child: selected && mark != OptionMark.idle && !context.reduceMotion
            ? TweenAnimationBuilder<double>(
                tween: Tween(begin: .9, end: 1),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: body,
              )
            : body,
      ),
    );
  }
}

/// Soru görseli yoksa Ulu Cami kubbeleri illüstrasyonu.
class QuizIllustration extends StatelessWidget {
  const QuizIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final f = p.buanFill.hex;
    final domes = [for (var k = 0; k < 5; k++) '<path d="M${66 + k * 38} 70 a19 19 0 0 1 38 0 z" fill="$f" opacity=".55"/>'].join();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 130,
        color: p.tile4,
        child: SvgArt(
          '<svg viewBox="0 0 313 130" preserveAspectRatio="xMidYMid slice"><rect x="56" y="70" width="200" height="60" fill="$f" opacity=".25"/>$domes'
          '<rect x="262" y="20" width="12" height="110" fill="$f" opacity=".55"/><rect x="40" y="30" width="12" height="100" fill="$f" opacity=".55"/></svg>',
          width: double.infinity,
          height: 130,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Cevap sonrası geri bildirim kutusu.
class QuizFeedback extends StatelessWidget {
  const QuizFeedback({super.key, required this.text, required this.correct});

  final String text;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: correct ? p.grnS : p.errorSoft, borderRadius: BorderRadius.circular(20)),
        child: Text(
          text,
          style: AppTypography.body(14, weight: FontWeight.w800, height: 1.45, color: correct ? p.grnT : p.errorText),
        ),
      ),
    );
  }
}

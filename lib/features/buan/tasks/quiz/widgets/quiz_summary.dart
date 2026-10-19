import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../l10n/l10n.dart';

/// Quiz sonu: maskot + "4 / 5 doğru" + kazanılan BUAN (sunucunun verdiği).
class QuizSummary extends StatefulWidget {
  const QuizSummary({super.key, required this.correct, required this.total, required this.awarded});

  final int correct, total, awarded;

  @override
  State<QuizSummary> createState() => _QuizSummaryState();
}

class _QuizSummaryState extends State<QuizSummary> {
  @override
  void initState() {
    super.initState();
    if (widget.awarded > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showRewardToast(context, label: context.l10n.taskQuizToast, amount: widget.awarded);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final won = widget.awarded > 0;
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Blob(shape: BlobShape.f, color: p.mint, width: 260),
                    Mascot(mood: won ? MascotMood.celebrate : MascotMood.happy, size: 160),
                  ],
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    l.taskQuizSummaryTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.display(28, color: p.ink),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.taskQuizSummaryScore(widget.correct, widget.total),
                  style: AppTypography.body(17, weight: FontWeight.w800, color: p.mut),
                ),
                const SizedBox(height: 12),
                if (won) Text(l.buanAmount(Fmt.signed(widget.awarded)), style: AppTypography.number(40, color: p.buanFill)),
                const SizedBox(height: 28),
                AppButton(label: l.taskQuizSummaryBack, onPressed: () => Navigator.of(context).maybePop()),
              ],
            ),
          ),
        ),
        Positioned.fill(child: CelebrationOverlay(play: won)),
      ],
    );
  }
}

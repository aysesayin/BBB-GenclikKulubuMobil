import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../l10n/l10n.dart';

/// 250 px hedef halkası: adım ikonu + sayı + "/ 8.000 adım".
class StepsGoalRing extends StatelessWidget {
  const StepsGoalRing({super.key, required this.steps, required this.goal, required this.progress});

  final int steps, goal;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Semantics(
      label: l.taskStepsRingSemantics(Fmt.number(steps), Fmt.number(goal)),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: context.reduceMotion ? Duration.zero : AppDurations.countUp,
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => ProgressRing(value: v, size: 250, stroke: 22, color: p.secondary, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.steps, size: 30, color: p.grnT),
            const SizedBox(height: 2),
            CountUpText(
              value: steps,
              style: AppTypography.number(46, height: 1, color: p.ink),
            ),
            const SizedBox(height: 2),
            Text(
              l.taskStepsOfGoal(Fmt.number(goal)),
              style: AppTypography.body(14, weight: FontWeight.w800, color: p.mut),
            ),
          ],
        ),
      ),
    );
  }
}

/// "4,6 km" gibi küçük yüzey çipi.
class StepsStatChip extends StatelessWidget {
  const StepsStatChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(17)),
      child: Center(
        widthFactor: 1,
        child: Text(label, style: AppTypography.number(13, color: p.ink)),
      ),
    );
  }
}

/// Sensöre erişilemediğinde açıklama kartı (web / izin reddi / donanım yok).
class StepsSensorNotice extends StatelessWidget {
  const StepsSensorNotice({super.key, required this.denied, this.onSettings, this.onRetry});

  final bool denied;
  final VoidCallback? onSettings, onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return AppCard(
      color: p.yelS,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.info, size: 22, color: p.warningText, strokeWidth: 2.4),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.taskStepsNoSensorTitle,
                  style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
                ),
                const SizedBox(height: 4),
                Text(denied ? l.taskStepsDeniedBody : l.taskStepsUnsupportedBody, style: AppTypography.body(13, color: p.ink, height: 1.35)),
                if (onSettings != null || onRetry != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (onSettings != null)
                        AppButton(
                          label: l.taskStepsOpenSettings,
                          onPressed: onSettings,
                          variant: AppButtonVariant.outlineInk,
                          size: AppButtonSize.small,
                          expand: false,
                        ),
                      if (onRetry != null) AppButton.text(label: l.commonRetry, onPressed: onRetry, size: AppButtonSize.small, expand: false),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

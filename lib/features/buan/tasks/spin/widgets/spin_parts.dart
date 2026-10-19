import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../l10n/l10n.dart';

/// Koyu zemin üzerinde iki seçenekli sekme (Çark / Salla Kazan).
class SpinModeTabs extends StatelessWidget {
  const SpinModeTabs({super.key, required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.paper.withValues(alpha: .12), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                child: GestureDetector(
                  onTap: () {
                    Haptics.selection();
                    onChanged(i);
                  },
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: i == index ? p.paper : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                    child: Text(
                      labels[i],
                      style: AppTypography.body(14, weight: FontWeight.w900, color: i == index ? p.onTile : p.paper),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Bugün 1 hakkın var" yarı saydam çip.
class SpinChanceChip extends StatelessWidget {
  const SpinChanceChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.paper.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)),
      child: Text(
        label,
        style: AppTypography.body(12, weight: FontWeight.w900, color: p.onNight),
      ),
    );
  }
}

/// Kazanç penceresi: scrim + pop kartı (450 ms easeOutBack).
class SpinWinDialog extends StatelessWidget {
  const SpinWinDialog({super.key, required this.amount, required this.onClose});

  final int amount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(30)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(mood: MascotMood.celebrate, size: 90),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              l.taskSpinWinTitle,
              textAlign: TextAlign.center,
              style: AppTypography.display(26, color: p.onTile),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(l.buanAmount(Fmt.signed(amount)), style: AppTypography.number(48, color: p.buanFill)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.taskSpinWinNote,
            textAlign: TextAlign.center,
            style: AppTypography.body(14, color: p.onTile.withValues(alpha: .7)),
          ),
          const SizedBox(height: 18),
          AppButton(label: l.taskSpinWinCta, onPressed: onClose),
        ],
      ),
    );
    return Positioned.fill(
      child: ColoredBox(
        color: p.scrim,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: context.reduceMotion ? 1 : .6, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: const Cubic(.34, 1.56, .64, 1),
                builder: (_, v, child) => Opacity(
                  opacity: ((v - .6) / .4).clamp(0, 1),
                  child: Transform.scale(scale: v, child: child),
                ),
                child: card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

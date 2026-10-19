import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../l10n/l10n.dart';

/// "Bu hafta" kartı: 7 çubuk, kesikli hedef çizgisi; hedefi tutan günler yeşil,
/// bugün turkuaz + ink çerçeve. Çubuk etiketleri ekran okuyucuya okunur.
class StepsWeekChart extends StatelessWidget {
  const StepsWeekChart({super.key, required this.days, required this.goal, required this.goalDays, required this.targetDays});

  /// (gün, adım) — sonuncusu bugün.
  final List<(DateTime, int)> days;
  final int goal, goalDays, targetDays;

  static const _barMax = 110.0;
  static const _labelH = 22.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final peak = days.fold<int>(goal, (m, d) => d.$2 > m ? d.$2 : m);
    final max = peak * 1.1;
    double h(int v) => (v / max * _barMax).clamp(8, _barMax);
    return AppCard(
      radius: AppRadii.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l.taskStepsWeek, style: AppTypography.display(18, color: p.ink)),
                ),
              ),
              Text(
                l.taskStepsWeekGoal(goalDays, targetDays),
                style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _barMax + _labelH + 8,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: h(goal) + _labelH,
                  child: CustomPaint(size: const Size(double.infinity, 2), painter: _DashPainter(p.line)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < days.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _bar(context, days[i], today: i == days.length - 1, height: h(days[i].$2), locale: locale),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, (DateTime, int) d, {required bool today, required double height, required String locale}) {
    final p = context.palette;
    final l = context.l10n;
    final hit = d.$2 >= goal;
    final day = Fmt.weekdayShort(d.$1, locale);
    final steps = Fmt.number(d.$2);
    return Semantics(
      label: hit ? l.taskStepsBarDone(day, steps) : l.taskStepsBar(day, steps),
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: hit ? p.secondary : (today ? p.primary : p.sf2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(4)),
              border: today ? Border.all(color: p.ink, width: 2) : null,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: _labelH - 6,
            child: FittedBox(
              child: Text(
                day,
                style: AppTypography.body(11, weight: FontWeight.w900, color: today ? p.ink : p.mut),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 1), Offset(x + 5, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.color != color;
}

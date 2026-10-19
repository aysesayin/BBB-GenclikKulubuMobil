import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/l10n.dart';
import 'event_format.dart';

/// G1 takvim şeridi: 54×72 gün kutuları, etkinlik olan günlerde nokta.
class DayStrip extends StatelessWidget {
  const DayStrip({super.key, required this.days, required this.isSelected, required this.hasEvents, required this.onPick});

  final List<DateTime> days;
  final bool Function(DateTime) isSelected;
  final bool Function(DateTime) hasEvents;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.eventDayPickerLabel,
        container: true,
        child: SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _DayButton(
              day: days[i],
              selected: isSelected(days[i]),
              dot: hasEvents(days[i]),
              onTap: () => onPick(days[i]),
            ),
          ),
        ),
      );
}

class _DayButton extends StatelessWidget {
  const _DayButton({required this.day, required this.selected, required this.dot, required this.onTap});

  final DateTime day;
  final bool selected, dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.bg : p.ink;
    final full = EventFormat.fullDay(context, day);
    return Semantics(
      button: true,
      selected: selected,
      label: dot ? context.l10n.eventDayHasEvents(full) : full,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.chip,
          width: 54,
          height: 72,
          decoration: BoxDecoration(
            color: selected ? p.ink : p.sf,
            borderRadius: BorderRadius.circular(18),
            border: selected ? null : Border.all(color: p.line, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(EventFormat.weekdayShort(context, day), style: AppTypography.body(12, weight: FontWeight.w800, color: fg)),
              const SizedBox(height: 2),
              Text('${day.day}', style: AppTypography.display(22, height: 1, color: fg)),
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dot ? (selected ? p.cta : p.primary) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

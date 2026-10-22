import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/services/session.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/svc_format.dart';
import '../view_model/session_view_model.dart';
import 'session_cell.dart';

const _timeCol = 46.0;
const _gap = 6.0;

/// Haftalık ızgara: 46 px saat sütunu + 7 × 104 px gün; yatay ve dikey kaydırılır.
class SessionGrid extends StatelessWidget {
  const SessionGrid({super.key, required this.vm});

  final SessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final days = vm.days;
    final rows = vm.rowMinutes;
    return Semantics(
      label: context.l10n.svcGridLabel,
      container: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 12, bottom: 24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const SizedBox(width: _timeCol),
                for (final d in days) ...[const SizedBox(width: _gap), SessionDayHeader(day: d, today: vm.isToday(d.date))],
              ]),
              for (final m in rows)
                Padding(
                  padding: const EdgeInsets.only(top: _gap),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SessionTimeLabel(minute: m),
                      for (final d in days) ...[
                        const SizedBox(width: _gap),
                        SlotCell(vm: vm, day: d, slot: vm.slotAt(d.date, m), minute: m),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sol saat etiketi ("08:00").
class SessionTimeLabel extends StatelessWidget {
  const SessionTimeLabel({super.key, required this.minute});

  final int minute;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: _timeCol,
        height: kCellH,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(SvcFmt.minuteLabel(minute), style: AppTypography.number(12, color: context.palette.mut)),
        ),
      );
}

/// Gün başlığı: "Pzt 12" + bugün / tatil / bakım notu.
class SessionDayHeader extends StatelessWidget {
  const SessionDayHeader({super.key, required this.day, required this.today, this.width = kCellW});

  final SessionDay day;
  final bool today;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final holiday = day.status == DayStatus.holiday;
    final closed = day.status == DayStatus.maintenance || day.status == DayStatus.closed;
    final (bg, fg, note) = today
        ? (p.tealS, p.ink, l.svcDayToday)
        : holiday
            ? (p.yelS, p.warningText, l.svcDayHoliday)
            : closed
                ? (p.sf2, p.mut, l.svcDayMaintenance)
                : (p.sf, p.ink, '');
    return Container(
      width: width,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: today ? Border.all(color: p.teal, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(SvcFmt.dayHeader(context, day.date), style: AppTypography.body(13, weight: FontWeight.w900, color: fg)),
          if (note.isNotEmpty) Text(note, style: AppTypography.body(10, weight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/session.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../view_model/session_view_model.dart';

const _timeCol = 46.0;
const _cellW = 104.0;
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
                for (final d in days) ...[const SizedBox(width: _gap), _DayHeader(day: d, today: vm.isToday(d.date))],
              ]),
              for (final m in rows)
                Padding(
                  padding: const EdgeInsets.only(top: _gap),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TimeLabel(minute: m),
                      for (final d in days) ...[
                        const SizedBox(width: _gap),
                        _SlotCell(vm: vm, day: d, slot: vm.slotAt(d.date, m), minute: m),
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

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.minute});

  final int minute;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: _timeCol,
        height: 72,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(SvcFmt.minuteLabel(minute), style: AppTypography.number(12, color: context.palette.mut)),
        ),
      );
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.today});

  final SessionDay day;
  final bool today;

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
      width: _cellW,
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

class _SlotCell extends StatelessWidget {
  const _SlotCell({required this.vm, required this.day, required this.slot, required this.minute});

  final SessionViewModel vm;
  final SessionDay day;
  final SessionSlot? slot;
  final int minute;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final s = slot;
    final kind = vm.kindOf(s, day);
    if (kind == CellKind.empty) return const SizedBox(width: _cellW, height: 72);
    final cap = s == null ? '' : l.svcCellCapacity('${s.isFull ? s.capacity : s.booked}', '${s.capacity}');
    final price = s == null ? '' : SvcFmt.price(context, s.price);
    final label = s?.label ?? '';
    final (Color bg, Color fg, Color? border, String l1, String l2, String l3, String? icon) = switch (kind) {
      CellKind.holiday => (p.yelS, p.warningText, null, l.svcCellHoliday, '', l.svcCellClosed, AppIcons.calendar),
      CellKind.maintenance => (p.sf2, p.mut, null, label.isEmpty ? l.svcCellMaintenance : label, '', '', SvcIcons.wrench),
      CellKind.cancelled => (p.sf2, p.mut, null, label, l.svcCellCancelled, '', AppIcons.close),
      CellKind.full => (p.pinkS, p.pinkT, null, label, l.svcCellFull, cap, null),
      CellKind.past => (p.sf2, p.mut, null, label, price, l.svcCellPast, null),
      CellKind.selected => (p.onTile, p.paper, null, label, price, cap, AppIcons.check),
      _ => (p.sf, p.ink, p.line, label, price, cap, null),
    };
    final enabled = kind == CellKind.open || kind == CellKind.selected;
    final style = AppTypography.number(11, color: fg, height: 1.15);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: kind == CellKind.selected,
      excludeSemantics: true,
      label: l.svcCellSemantics(SvcFmt.dayHeader(context, day.date), SvcFmt.minuteLabel(minute), l1, [l2, l3].where((e) => e.isNotEmpty).join(' ')),
      child: GestureDetector(
        onTap: enabled && s != null
            ? () {
                Haptics.selection();
                vm.select(s, day);
              }
            : null,
        child: AnimatedContainer(
          duration: AppDurations.chip,
          width: _cellW,
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border == null ? null : Border.all(color: border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: style.copyWith(decoration: kind == CellKind.cancelled ? TextDecoration.lineThrough : null, decorationColor: fg),
                    ),
                  ),
                  if (icon != null) AppIcon(icon, size: 12, color: fg, strokeWidth: 2.8),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text(l2, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: style)),
                  Text(l3, maxLines: 1, style: style),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

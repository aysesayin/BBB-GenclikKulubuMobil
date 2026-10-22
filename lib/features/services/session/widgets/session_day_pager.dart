import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../view_model/session_view_model.dart';
import 'session_cell.dart';
import 'session_grid.dart';

/// Kolay Mod: haftalık ızgara yerine tek gün; 56 px "Önceki gün / Sonraki gün" düğmeleri,
/// tam genişlikte hücreler.
class SessionDayPager extends StatelessWidget {
  const SessionDayPager({super.key, required this.vm});

  final SessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final day = vm.focusSessionDay;
    final slots = vm.slotsOn(day.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Row(
            children: [
              AppIconButton(
                icon: SvcIcons.chevronLeft,
                semanticLabel: l.svcDayPrev,
                size: 56,
                iconSize: 26,
                background: p.sf,
                color: vm.canGoPrevDay ? p.ink : p.line,
                onPressed: vm.canGoPrevDay ? vm.prevDay : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: SessionDayHeader(day: day, today: vm.isToday(day.date), width: null)),
              const SizedBox(width: 10),
              AppIconButton(icon: AppIcons.chevronRight, semanticLabel: l.svcDayNext, size: 56, iconSize: 26, background: p.sf, onPressed: vm.nextDay),
            ],
          ),
        ),
        Expanded(
          child: slots.isEmpty
              ? EmptyState(title: l.svcEasyNoSessionsDay, message: l.svcNoSessionsMessage)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: slots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = slots[i];
                    final minute = s.start.hour * 60 + s.start.minute;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 56,
                          height: kCellH,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(SvcFmt.minuteLabel(minute), style: AppTypography.number(14, color: p.mut)),
                          ),
                        ),
                        Expanded(child: SlotCell(vm: vm, day: day, slot: s, minute: minute, width: null)),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

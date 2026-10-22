import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'event_format.dart';
import 'events_icons.dart';

/// G1 takvim şeridi: üstte ay etiketi ("Ekim 2026") + haftalık ileri/geri okları (44 px),
/// altta 54×72 gün kutuları (Kolay Mod: 72×80). Kaydırma korunur; oklar bir hafta atlar.
class DayStrip extends StatefulWidget {
  const DayStrip({super.key, required this.days, required this.isSelected, required this.hasEvents, required this.onPick});

  final List<DateTime> days;
  final bool Function(DateTime) isSelected;
  final bool Function(DateTime) hasEvents;
  final ValueChanged<DateTime> onPick;

  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  static const _gap = 8.0;
  static const _hPad = 20.0;

  final _scroll = ScrollController();
  int _firstVisible = 0;

  /// build'de okunur; kaydırma dinleyicisi `select` çağıramaz.
  bool _easy = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _tileW(bool easy) => easy ? 72 : 54;

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final step = _tileW(_easy) + _gap;
    final i = (_scroll.offset / step).round().clamp(0, widget.days.isEmpty ? 0 : widget.days.length - 1);
    if (i != _firstVisible) setState(() => _firstVisible = i);
  }

  void _jump(int weeks) {
    if (!_scroll.hasClients) return;
    final step = _tileW(_easy) + _gap;
    final target = (_scroll.offset + weeks * 7 * step).clamp(0.0, _scroll.position.maxScrollExtent);
    Haptics.selection();
    if (context.reduceMotion) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: AppDurations.sheet, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final easy = _easy = context.easyMode;
    final days = widget.days;
    final anchor = days.isEmpty ? DateTime.now() : days[_firstVisible.clamp(0, days.length - 1)];
    final w = _tileW(easy);
    final h = easy ? 80.0 : 72.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, 6, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    EventFormat.monthYear(context, anchor),
                    style: AppTypography.body(easy ? 16 : 14, weight: FontWeight.w900, color: p.mut),
                  ),
                ),
              ),
              AppIconButton(icon: EventIcons.chevronLeft, semanticLabel: l.eventStripPrevWeek, background: p.sf, iconSize: 18, onPressed: () => _jump(-1)),
              const SizedBox(width: 4),
              AppIconButton(icon: AppIcons.chevronRight, semanticLabel: l.eventStripNextWeek, background: p.sf, iconSize: 18, onPressed: () => _jump(1)),
            ],
          ),
        ),
        Semantics(
          label: l.eventDayPickerLabel,
          container: true,
          child: SizedBox(
            height: h + 12,
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 4),
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: _gap),
              itemBuilder: (context, i) => _DayButton(
                day: days[i],
                width: w,
                height: h,
                selected: widget.isSelected(days[i]),
                dot: widget.hasEvents(days[i]),
                onTap: () => widget.onPick(days[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({required this.day, required this.width, required this.height, required this.selected, required this.dot, required this.onTap});

  final DateTime day;
  final double width, height;
  final bool selected, dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.bg : p.ink;
    final full = EventFormat.fullDay(context, day);
    final big = width >= 72;
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
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: selected ? p.ink : p.sf,
            borderRadius: BorderRadius.circular(18),
            border: selected ? null : Border.all(color: p.line, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(EventFormat.weekdayShort(context, day), style: AppTypography.body(big ? 13 : 12, weight: FontWeight.w800, color: fg)),
              const SizedBox(height: 2),
              Text('${day.day}', style: AppTypography.display(big ? 26 : 22, height: 1, color: fg)),
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

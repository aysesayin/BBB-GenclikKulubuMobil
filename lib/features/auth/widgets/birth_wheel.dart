import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/l10n.dart';

/// Doğum tarihi tekerleği: gün · ay · yıl (1 : 1.6 : 1.2), 170 px, ortada
/// turkuaz-açık seçim bandı. Ekran okuyucuda her sütun artır/azalt ayarlayıcı.
class BirthWheel extends StatelessWidget {
  const BirthWheel({super.key, required this.value, required this.firstYear, required this.lastYear, required this.onChanged});

  final DateTime value;
  final int firstYear, lastYear;
  final ValueChanged<DateTime> onChanged;

  static int _days(int y, int m) => DateTime(y, m + 1, 0).day;

  void _set({int? d, int? m, int? y}) {
    final year = y ?? value.year, month = m ?? value.month;
    final day = (d ?? value.day).clamp(1, _days(year, month));
    Haptics.selection();
    onChanged(DateTime(year, month, day));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final months = [for (var m = 1; m <= 12; m++) DateFormat.MMMM(locale).format(DateTime(2000, m))];
    return Container(
      height: 170,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(22)),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 10,
            top: 62,
            height: 46,
            child: DecoratedBox(decoration: BoxDecoration(color: p.tealS, borderRadius: BorderRadius.circular(14))),
          ),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: _Column(
                  label: l.authWheelDay,
                  count: _days(value.year, value.month),
                  selected: value.day - 1,
                  text: (i) => '${i + 1}',
                  onSelected: (i) => _set(d: i + 1),
                ),
              ),
              Expanded(
                flex: 16,
                child: _Column(label: l.authWheelMonth, count: 12, selected: value.month - 1, text: (i) => months[i], onSelected: (i) => _set(m: i + 1)),
              ),
              Expanded(
                flex: 12,
                child: _Column(
                  label: l.authWheelYear,
                  count: lastYear - firstYear + 1,
                  selected: (value.year - firstYear).clamp(0, lastYear - firstYear),
                  text: (i) => '${firstYear + i}',
                  onSelected: (i) => _set(y: firstYear + i),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Column extends StatefulWidget {
  const _Column({required this.label, required this.count, required this.selected, required this.text, required this.onSelected});

  final String label;
  final int count, selected;
  final String Function(int) text;
  final ValueChanged<int> onSelected;

  @override
  State<_Column> createState() => _ColumnState();
}

class _ColumnState extends State<_Column> {
  late final FixedExtentScrollController _c = FixedExtentScrollController(initialItem: widget.selected);

  @override
  void didUpdateWidget(_Column old) {
    super.didUpdateWidget(old);
    if (_c.hasClients && _c.selectedItem != widget.selected) {
      _c.jumpToItem(widget.selected);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = widget.selected;
    return Semantics(
      label: widget.label,
      value: widget.text(s),
      increasedValue: s < widget.count - 1 ? widget.text(s + 1) : null,
      decreasedValue: s > 0 ? widget.text(s - 1) : null,
      onIncrease: s < widget.count - 1 ? () => widget.onSelected(s + 1) : null,
      onDecrease: s > 0 ? () => widget.onSelected(s - 1) : null,
      excludeSemantics: true,
      child: ListWheelScrollView.useDelegate(
        controller: _c,
        itemExtent: 38,
        diameterRatio: 2.2,
        perspective: .002,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) {
          if (i != widget.selected) widget.onSelected(i);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.count,
          builder: (_, i) {
            final d = (i - s).abs();
            return Center(
              child: Opacity(
                opacity: d == 0 ? 1 : (d == 1 ? .45 : .18),
                child: Text(
                  widget.text(i),
                  maxLines: 1,
                  style: AppTypography.display(d == 0 ? 24 : 18, height: 1, color: p.ink),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/services/facility.dart';
import '../../../l10n/l10n.dart';

/// Hizmetler ekranlarında ortak para / tarih / renk biçimleri.
abstract final class SvcFmt {
  static String _locale(BuildContext c) => Localizations.localeOf(c).toString();

  /// 1200 → "1.200 ₺", 0 → "Ücretsiz".
  static String price(BuildContext c, num v) => v <= 0 ? c.l10n.svcFree : c.l10n.svcPrice(_plain(v));

  /// Her zaman 2 hane: 100 → "100,00 ₺" (toplamlar).
  static String money(BuildContext c, num v) => c.l10n.svcPrice(NumberFormat('#,##0.00', 'tr').format(v));

  static String _plain(num v) => v % 1 == 0 ? Fmt.number(v) : NumberFormat('#,##0.##', 'tr').format(v);

  static String unit(BuildContext c, PriceUnit u) => switch (u) {
        PriceUnit.session => c.l10n.svcUnitSession,
        PriceUnit.term => c.l10n.svcUnitTerm,
        PriceUnit.monthly => c.l10n.svcUnitMonthly,
        PriceUnit.hourly => c.l10n.svcUnitHourly,
        PriceUnit.unknown => '',
      };

  /// "Cum 16"
  static String dayHeader(BuildContext c, DateTime d) => '${DateFormat.E(_locale(c)).format(d)} ${d.day}';

  /// "Cum 16 Eki"
  static String dayMonth(BuildContext c, DateTime d) => DateFormat('E d MMM', _locale(c)).format(d).replaceAll('.', '');

  static String time(BuildContext c, DateTime d) => Fmt.time(d, _locale(c));

  /// "18:00" — günün dakikasından.
  static String minuteLabel(int minuteOfDay) =>
      '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:${(minuteOfDay % 60).toString().padLeft(2, '0')}';

  /// "12 – 18 Ekim" / "26 Eki – 1 Kas".
  static String weekRange(BuildContext c, DateTime start, DateTime end) {
    final loc = _locale(c);
    if (start.month == end.month) {
      return c.l10n.svcWeekRange('${start.day}', DateFormat('d MMMM', loc).format(end));
    }
    final f = DateFormat('d MMM', loc);
    return c.l10n.svcWeekRange(f.format(start).replaceAll('.', ''), f.format(end).replaceAll('.', ''));
  }

  static String shortDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

  /// API'deki 1–6 karo indeksi → palette rengi.
  static Color tile(AppPalette p, int index) => p.tiles[(index - 1).clamp(0, 5)];
}

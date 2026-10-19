import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Etkinlik tarih biçimleri (yerel ayara göre; Türkçede "18 Eki Paz · 08:30").
abstract final class EventFormat {
  static String _loc(BuildContext context) => Localizations.localeOf(context).languageCode;

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Kart rozeti: tek gün → "18 Eki Paz · 08:30", çok gün → "24–26 Eki".
  static String cardWhen(BuildContext context, DateTime start, DateTime? end) {
    final l = _loc(context);
    if (end == null || _sameDay(start, end)) {
      return '${DateFormat('d MMM E', l).format(start)} · ${DateFormat.Hm(l).format(start)}';
    }
    return _range(start, end, 'MMM', l);
  }

  /// Detay satırı: "18 Ekim Pazar · 08:30–14:00" ya da "24–26 Ekim".
  static String detailWhen(BuildContext context, DateTime start, DateTime? end) {
    final l = _loc(context);
    if (end == null) return '${DateFormat('d MMMM EEEE', l).format(start)} · ${DateFormat.Hm(l).format(start)}';
    if (_sameDay(start, end)) {
      return '${DateFormat('d MMMM EEEE', l).format(start)} · ${DateFormat.Hm(l).format(start)}–${DateFormat.Hm(l).format(end)}';
    }
    return _range(start, end, 'MMMM', l);
  }

  static String _range(DateTime start, DateTime end, String month, String l) {
    if (start.month == end.month && start.year == end.year) {
      return '${start.day}–${DateFormat('d $month', l).format(end)}';
    }
    return '${DateFormat('d $month', l).format(start)} – ${DateFormat('d $month', l).format(end)}';
  }

  static String dayMonth(BuildContext context, DateTime d) => DateFormat('d MMMM', _loc(context)).format(d);
  static String monthYear(BuildContext context, DateTime d) => DateFormat.yMMMM(_loc(context)).format(d);
  static String weekdayShort(BuildContext context, DateTime d) => DateFormat.E(_loc(context)).format(d);
  static String fullDay(BuildContext context, DateTime d) => DateFormat('d MMMM EEEE', _loc(context)).format(d);
}

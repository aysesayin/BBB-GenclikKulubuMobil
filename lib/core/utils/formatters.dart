import 'package:intl/intl.dart';

/// Sayı / tarih / maske biçimleri (tr_TR: binlik ayırıcı nokta).
abstract final class Fmt {
  static final _int = NumberFormat.decimalPattern('tr');

  /// 12450 → "12.450"
  static String number(num v) => _int.format(v);

  /// 2000 → "+2.000", -8000 → "−8.000" (gerçek eksi işareti).
  static String signed(num v) => v >= 0 ? '+${number(v)}' : '−${number(v.abs())}';

  /// TCKN maskeleme (KVKK): 12345678901 → "1234*****01".
  static String maskTckn(String tckn) {
    final d = tckn.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return '***********';
    return '${d.substring(0, 4)}*****${d.substring(9)}';
  }

  /// Telefon maskeleme: 05321234567 → "0532 *** ** 67".
  static String maskPhone(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.length < 10) return phone;
    final n = d.length == 10 ? '0$d' : d;
    return '${n.substring(0, 4)} *** ** ${n.substring(n.length - 2)}';
  }

  /// Telefonu yazarken gruplama: "0532 000 00 00".
  static String groupPhone(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 4 || i == 7 || i == 9) b.write(' ');
      b.write(d[i]);
    }
    return b.toString();
  }

  /// "18 EKİ" kısaltması için ay (Türkçe büyük harf kuralıyla).
  static String monthShort(DateTime d, [String locale = 'tr']) =>
      trUpper(DateFormat.MMM(locale).format(d)).replaceAll('.', '');

  static String dayMonth(DateTime d, [String locale = 'tr']) => DateFormat.MMMMd(locale).format(d);
  static String time(DateTime d, [String locale = 'tr']) => DateFormat.Hm(locale).format(d);
  static String weekdayShort(DateTime d, [String locale = 'tr']) => DateFormat.E(locale).format(d);
  static String fullDate(DateTime d, [String locale = 'tr']) => DateFormat.yMMMMd(locale).format(d);

  /// 5 dk sayaç: 274 sn → "04:34".
  static String mmss(Duration d) {
    final s = d.inSeconds.clamp(0, 359999);
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// Uzun sayaç: 1s 2dk 5sn → "01:02:05"; bir saatten azsa mm:ss.
  static String hhmmss(Duration d) {
    final s = d.inSeconds.clamp(0, 359999);
    if (s < 3600) return mmss(d);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two(s % 3600 ~/ 60)}:${two(s % 60)}';
  }

  /// Para: 120.5 → "120,50 ₺".
  static String currency(num v) => NumberFormat.currency(locale: 'tr', symbol: '₺', decimalDigits: v % 1 == 0 ? 0 : 2).format(v);
}

/// Türkçe büyük harf dönüşümü: i → İ, ı → I (String.toUpperCase bunu yapmaz).
String trUpper(String s) => s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Türkçe küçük harf dönüşümü: İ → i, I → ı.
String trLower(String s) => s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

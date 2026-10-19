/// Form doğrulayıcılar. Hata durumunda l10n anahtarı değil, [ValidationIssue]
/// döner; görünüm bunu yerelleştirilmiş metne çevirir.
enum ValidationIssue { required, tcknLength, tcknInvalid, phoneInvalid, emailInvalid, passwordWeak, otpLength, underAge }

abstract final class Validators {
  /// T.C. Kimlik No algoritma kontrolü:
  /// 11 hane, ilk hane 0 değil;
  /// d10 = ((d1+d3+d5+d7+d9)*7 − (d2+d4+d6+d8)) mod 10;
  /// d11 = (d1+…+d10) mod 10.
  static bool isValidTckn(String input) {
    final s = input.replaceAll(RegExp(r'\D'), '');
    if (s.length != 11 || s[0] == '0') return false;
    final d = s.split('').map(int.parse).toList();
    final odd = d[0] + d[2] + d[4] + d[6] + d[8];
    final even = d[1] + d[3] + d[5] + d[7];
    final d10 = ((odd * 7) - even) % 10;
    if (d10 < 0 || d[9] != d10) return false;
    final d11 = d.take(10).fold<int>(0, (a, b) => a + b) % 10;
    return d[10] == d11;
  }

  static ValidationIssue? tckn(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.isEmpty) return ValidationIssue.required;
    if (s.length != 11) return ValidationIssue.tcknLength;
    return isValidTckn(s) ? null : ValidationIssue.tcknInvalid;
  }

  /// Türkiye cep telefonu: 05XX XXX XX XX (10 ya da 11 hane).
  static ValidationIssue? phone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.isEmpty) return ValidationIssue.required;
    final n = s.length == 10 ? '0$s' : s;
    return RegExp(r'^05\d{9}$').hasMatch(n) ? null : ValidationIssue.phoneInvalid;
  }

  static ValidationIssue? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return ValidationIssue.required;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(s) ? null : ValidationIssue.emailInvalid;
  }

  /// En az 8 karakter, 1 harf, 1 rakam.
  static ValidationIssue? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return ValidationIssue.required;
    final ok = s.length >= 8 && RegExp('[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(s) && RegExp(r'\d').hasMatch(s);
    return ok ? null : ValidationIssue.passwordWeak;
  }

  static ValidationIssue? otp(String? v, {int length = 6}) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    return s.length == length ? null : ValidationIssue.otpLength;
  }

  static ValidationIssue? required(String? v) => (v ?? '').trim().isEmpty ? ValidationIssue.required : null;

  /// Yaş hesabı (doğum günü geçmediyse bir eksik).
  static int ageOn(DateTime birth, DateTime today) {
    var age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) age--;
    return age;
  }
}

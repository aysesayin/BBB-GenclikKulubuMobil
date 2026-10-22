import 'package:flutter/foundation.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/auth/auth_requests.dart';

enum TcknStatus { incomplete, valid, invalid }

/// Kayıt formunun düz alanları (kimlik, cep telefonu, sözleşmeler, veli telefonu)
/// ve doğrulamaları. E-posta ve acil durum kişisi kayıtta sorulmaz (profilden
/// tamamlanır). Akış mantığı [RegisterViewModel]'de.
mixin RegisterForm on BaseViewModel {
  static String digits(String v) => v.replaceAll(RegExp(r'\D'), '');

  int _shake = 0;

  /// Hatalı girişte artar → görünüm sallanır + errorImpact.
  int get shakeTick => _shake;

  @protected
  void bumpShake() => _shake++;

  // ---- Kimlik ----
  String _tckn = '';
  String get tckn => _tckn;
  TcknStatus get tcknStatus =>
      _tckn.length < 11 ? TcknStatus.incomplete : (Validators.isValidTckn(_tckn) ? TcknStatus.valid : TcknStatus.invalid);

  DateTime? _birth;
  DateTime get birthDate => _birth!;

  /// `yyyy-MM-dd`
  String get birthIso {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${birthDate.year.toString().padLeft(4, '0')}-${two(birthDate.month)}-${two(birthDate.day)}';
  }

  void setTckn(String v) {
    final d = digits(v);
    _tckn = d.length > 11 ? d.substring(0, 11) : d;
    if (tcknStatus == TcknStatus.invalid) _shake++;
    notify();
  }

  void setBirthDate(DateTime d) {
    _birth = d;
    notify();
  }

  // ---- İletişim (yalnız cep telefonu) ----
  String _phone = '';
  String get phone => _phone;

  /// 11 haneli (0 ile başlayan) cep telefonu.
  String get phone11 => _phone.length == 10 ? '0$_phone' : _phone;
  ValidationIssue? get phoneIssue => Validators.phone(_phone);

  void setPhone(String v) {
    _phone = digits(v);
    notify();
  }

  // ---- Sözleşmeler (4 zorunlu) + ayrı Açık Rıza (KVKK) ----
  final Set<LegalDoc> _accepted = {};
  bool _explicit = false;
  bool isAccepted(LegalDoc d) => _accepted.contains(d);
  bool get allRequiredAccepted => LegalDoc.required.every(_accepted.contains);
  bool get explicitConsent => _explicit;
  List<String> get acceptedKeys => [for (final d in LegalDoc.required) if (_accepted.contains(d)) d.key];

  void toggleConsent(LegalDoc d) {
    if (!_accepted.remove(d)) _accepted.add(d);
    notify();
  }

  void acceptConsent(LegalDoc d) {
    if (d == LegalDoc.explicitConsent) {
      _explicit = true;
    } else {
      _accepted.add(d);
    }
    notify();
  }

  void setExplicitConsent({required bool value}) {
    _explicit = value;
    notify();
  }

  // ---- Veli (16–17 yaş) ----
  String _parentPhone = '';
  String get parentPhone => _parentPhone;
  ValidationIssue? get parentPhoneIssue => Validators.phone(_parentPhone);

  void setParentPhone(String v) {
    _parentPhone = digits(v);
    notify();
  }
}

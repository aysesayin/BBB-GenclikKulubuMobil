import 'dart:async';

import '../../../../core/base/base_view_model.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../data/models/profile/account_settings.dart';
import '../../../../data/models/profile/user_profile.dart';
import '../../../../data/repositories/profile_repository.dart';
import 'biometric_login.dart';

class SettingsData {
  const SettingsData({required this.user, required this.prefs});

  final UserProfile user;
  final NotificationPrefs prefs;

  SettingsData copyWith({UserProfile? user, NotificationPrefs? prefs}) => SettingsData(user: user ?? this.user, prefs: prefs ?? this.prefs);
}

enum BiometricToggleResult { ok, unavailable, failed }

/// I2 · Hesap ayarları: iletişim özetleri, bildirim tercihleri (iyimser güncelleme),
/// biyometrik giriş, dil ve KVKK silme talebi. Tema doğrudan ThemeController'dadır.
class SettingsViewModel extends LoadableViewModel<SettingsData> {
  SettingsViewModel(this._repo, this._biometrics);

  final ProfileRepository _repo;
  final BiometricLogin _biometrics;

  BiometricKind? _biometricKind;
  BiometricKind? get biometricKind => _biometricKind;
  bool get biometricAvailable => _biometricKind != null;
  bool get biometricEnabled => _biometricKind != null && _biometrics.enabled;

  Future<void>? _biometricCheck;

  /// Cihaz yeteneği kontrolü ekran yüklemesini bekletmez (bazı cihazlarda yavaş / hiç dönmeyebilir).
  Future<void> get biometricReady => _biometricCheck ??= _checkBiometrics();

  Future<void> _checkBiometrics() async {
    _biometricKind = await _biometrics
        .availableKind()
        .then<BiometricKind?>((k) => k)
        .timeout(const Duration(seconds: 3), onTimeout: () => null);
    notify();
  }

  @override
  Future<ApiResult<SettingsData>> fetch() async {
    unawaited(biometricReady);
    final meFuture = _repo.me();
    final prefsFuture = _repo.preferences();
    final me = await meFuture;
    final prefs = await prefsFuture;
    return switch ((me, prefs)) {
      (Failure(:final error), _) || (_, Failure(:final error)) => Failure(error),
      (Success(data: final u, fromCache: final c1), Success(data: final pr, fromCache: final c2)) => Success(
        SettingsData(user: u, prefs: pr),
        fromCache: c1 || c2,
      ),
    };
  }

  SettingsData? get _data => state.dataOrNull;

  void _emit(SettingsData data) {
    final fromCache = switch (state) {
      ViewSuccess(:final fromCache) => fromCache,
      _ => false,
    };
    state = ViewSuccess(data, fromCache: fromCache);
  }

  /// İyimser güncelleme; hata olursa eski değere döner ve hatayı döndürür.
  Future<AppException?> updatePrefs(NotificationPrefs Function(NotificationPrefs) change) async {
    final data = _data;
    if (data == null) return null;
    final previous = data.prefs;
    final next = change(previous);
    if (next == previous) return null;
    _emit(data.copyWith(prefs: next));
    final result = await _repo.updatePreferences(next);
    if (isDisposed) return null;
    if (result case Failure(:final error)) {
      final current = _data;
      if (current != null) _emit(current.copyWith(prefs: previous));
      return error;
    }
    return null;
  }

  // TODO(varsayım): Uygulama dili şimdilik `app.dart`'ta 'tr' sabit; tercih sunucuya kaydedilir,
  // yerel dil değişimi için entegratörün bir LocaleController eklemesi gerekir.
  Future<AppException?> setLanguage(String code) => updatePrefs((p) => p.copyWith(language: code));

  Future<BiometricToggleResult> toggleBiometric({required bool on, required String reason}) async {
    if (!biometricAvailable) return BiometricToggleResult.unavailable;
    if (on) {
      final ok = await _biometrics.authenticate(reason);
      if (!ok) return BiometricToggleResult.failed;
    }
    await _biometrics.setEnabled(value: on);
    notify();
    return BiometricToggleResult.ok;
  }

  /// İletişim bilgisi / şifre değişince maskeli özetleri tazeler (iskelet göstermeden).
  Future<void> refreshUser() async {
    final result = await _repo.me();
    final data = _data;
    if (isDisposed || data == null) return;
    if (result case Success(data: final user)) _emit(data.copyWith(user: user));
  }

  /// KVKK hesap silme talebi. null → başarı.
  Future<AppException?> requestDeletion() async => switch (await _repo.requestDeletion()) {
    Success() => null,
    Failure(:final error) => error,
  };
}

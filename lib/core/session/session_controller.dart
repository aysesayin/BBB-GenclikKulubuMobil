import 'package:flutter/widgets.dart';

import '../storage/cache_store.dart';
import '../storage/secure_storage.dart';

enum SessionStatus { unknown, guest, authenticated }

/// Oturumdaki kullanıcının özet bilgisi (başlık, avatar baş harfleri).
/// Ayrıntılı profil `/users/me` ile ProfileRepository'den gelir.
@immutable
class SessionUser {
  const SessionUser({required this.id, required this.firstName, required this.lastName, this.avatarUrl});

  factory SessionUser.fromJson(Map<String, dynamic> j) => SessionUser(
        id: j['id'] as String,
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String?,
      );

  final String id, firstName, lastName;
  final String? avatarUrl;

  String get initials {
    String first(String s) => s.isEmpty ? '' : s.characters.first;
    return (first(firstName) + first(lastName)).toUpperCase();
  }

  /// KVKK: liderlik vb. herkese açık alanlarda "Ad S." biçimi.
  String get shortName => lastName.isEmpty ? firstName : '$firstName ${lastName.characters.first}.';

  Map<String, dynamic> toJson() => {'id': id, 'firstName': firstName, 'lastName': lastName, 'avatarUrl': avatarUrl};
}

/// Misafir / üye durumunu ve onboarding bayrağını tutar; router ve
/// [AuthGate] buna bakar.
class SessionController extends ChangeNotifier {
  SessionController({required SecureStorage secure, required CacheStore cache})
      : _secure = secure,
        _cache = cache;

  final SecureStorage _secure;
  final CacheStore _cache;

  static const _kOnboarding = 'pref.onboardingSeen';
  static const _kUser = 'user.session';

  SessionStatus _status = SessionStatus.unknown;
  SessionUser? _user;

  SessionStatus get status => _status;
  SessionUser? get user => _user;
  bool get isAuthenticated => _status == SessionStatus.authenticated;
  bool get isGuest => _status != SessionStatus.authenticated;
  bool get onboardingSeen => _cache.readBool(_kOnboarding) ?? false;

  /// Uygulama açılışında çağrılır (splash).
  Future<void> restore() async {
    final token = await _secure.accessToken;
    final json = _cache.readJson(_kUser);
    if (token != null && json != null) {
      _user = SessionUser.fromJson(json);
      _status = SessionStatus.authenticated;
    } else {
      _status = SessionStatus.guest;
    }
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    await _cache.writeBool(_kOnboarding, value: true);
    notifyListeners();
  }

  Future<void> signIn({required String accessToken, required String refreshToken, required SessionUser user}) async {
    await _secure.saveTokens(access: accessToken, refresh: refreshToken);
    await _cache.writeJson(_kUser, user.toJson());
    _user = user;
    _status = SessionStatus.authenticated;
    notifyListeners();
  }

  void continueAsGuest() {
    _status = SessionStatus.guest;
    notifyListeners();
  }

  Future<void> updateUser(SessionUser user) async {
    _user = user;
    await _cache.writeJson(_kUser, user.toJson());
    notifyListeners();
  }

  /// Çıkış ya da refresh başarısız olduğunda.
  Future<void> signOut() async {
    await _secure.clearTokens();
    await _cache.clearApiCache();
    _user = null;
    _status = SessionStatus.guest;
    notifyListeners();
  }
}

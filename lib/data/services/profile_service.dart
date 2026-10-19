import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/profile/account_settings.dart';
import '../models/profile/child_profile.dart';
import '../models/profile/discount.dart';
import '../models/profile/profile_stats.dart';
import '../models/profile/user_profile.dart';

/// Profil uç noktaları: kullanıcı, istatistik, iletişim, şifre, tercihler, çocuklar, indirimler, KVKK silme.
class ProfileService {
  ProfileService(this._client);

  final DioClient _client;

  static final _isoDate = DateFormat('yyyy-MM-dd');

  Future<ApiResult<UserProfile>> me() =>
      _client.get(ApiEndpoints.me, parse: (d) => UserProfile.fromJson(Json.map(d)), cacheKey: 'profile.me');

  Future<ApiResult<ProfileStats>> stats() =>
      _client.get(ApiEndpoints.meStats, parse: (d) => ProfileStats.fromJson(Json.map(d)), cacheKey: 'profile.stats');

  /// Yeni telefon / e-postaya OTP gönderir.
  Future<ApiResult<ContactChallenge>> updateContact(ContactKind kind, String value) => _client.put(
    ApiEndpoints.updateContact,
    body: {'type': kind.name, 'value': value},
    parse: (d) => ContactChallenge.fromJson(Json.map(d)),
  );

  Future<ApiResult<void>> verifyContact(String challengeId, String code) =>
      _client.post(ApiEndpoints.verifyOtp, body: {'purpose': 'contact', 'challengeId': challengeId, 'code': code}, parse: Json.ignore);

  Future<ApiResult<void>> changePassword({required String current, required String next}) =>
      _client.post(ApiEndpoints.changePassword, body: {'currentPassword': current, 'newPassword': next}, parse: Json.ignore);

  Future<ApiResult<NotificationPrefs>> preferences() =>
      _client.get(ApiEndpoints.preferences, parse: (d) => NotificationPrefs.fromJson(Json.map(d)), cacheKey: 'profile.preferences');

  Future<ApiResult<void>> updatePreferences(NotificationPrefs prefs) =>
      _client.put(ApiEndpoints.preferences, body: prefs.toJson(), parse: Json.ignore);

  Future<ApiResult<List<ChildProfile>>> children() =>
      _client.get(ApiEndpoints.children, parse: (d) => Json.list(d, ChildProfile.fromJson), cacheKey: 'profile.children');

  /// TCKN yalnız bu istekte gider; hiçbir yerde saklanmaz/önbelleğe yazılmaz (KVKK).
  Future<ApiResult<ChildProfile>> addChild({required String tckn, required DateTime birthDate}) => _client.post(
    ApiEndpoints.children,
    body: {'tckn': tckn, 'birthDate': _isoDate.format(birthDate), 'guardianDeclaration': true},
    parse: (d) => ChildProfile.fromJson(Json.map(d)),
  );

  Future<ApiResult<List<DiscountType>>> discountTypes() =>
      _client.get(ApiEndpoints.discountTypes, parse: (d) => Json.list(d, DiscountType.fromJson), cacheKey: 'profile.discountTypes');

  Future<ApiResult<List<UserDiscount>>> discounts() =>
      _client.get(ApiEndpoints.discounts, parse: (d) => Json.list(d, UserDiscount.fromJson), cacheKey: 'profile.discounts');

  Future<ApiResult<UserDiscount>> createDiscount(String typeId, {String? idempotencyKey}) => _client.post(
    ApiEndpoints.discounts,
    body: {'typeId': typeId},
    headers: idempotencyKey == null ? null : {'Idempotency-Key': idempotencyKey},
    parse: (d) => UserDiscount.fromJson(Json.map(d)),
  );

  Future<ApiResult<void>> uploadDiscountDocument(String discountId, {required String path, required String fileName}) async =>
      _client.upload(
        ApiEndpoints.discountDocument(discountId),
        form: FormData.fromMap({'file': await MultipartFile.fromFile(path, filename: fileName)}),
        parse: Json.ignore,
      );

  Future<ApiResult<void>> uploadAvatar({required String path, required String fileName}) async => _client.upload(
    ApiEndpoints.meAvatar,
    form: FormData.fromMap({'file': await MultipartFile.fromFile(path, filename: fileName)}),
    parse: Json.ignore,
  );

  Future<ApiResult<void>> requestDeletion({String? reason}) =>
      _client.post(ApiEndpoints.deleteAccount, body: {'reason': ?reason}, parse: Json.ignore);

  Future<ApiResult<void>> logout() => _client.post(ApiEndpoints.logout, parse: Json.ignore);
}

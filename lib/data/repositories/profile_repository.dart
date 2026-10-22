import '../../core/network/api_result.dart';
import '../models/profile/account_settings.dart';
import '../models/profile/child_profile.dart';
import '../models/profile/delete_request.dart';
import '../models/profile/discount.dart';
import '../models/profile/profile_stats.dart';
import '../models/profile/user_profile.dart';
import '../services/profile_service.dart';

/// Profil, hesap ayarları, çocuk ve indirim işlemleri.
abstract interface class ProfileRepository {
  Future<ApiResult<UserProfile>> me();
  Future<ApiResult<ProfileStats>> stats();

  Future<ApiResult<ContactChallenge>> updateContact(ContactKind kind, String value);
  Future<ApiResult<void>> verifyContact(String challengeId, String code);
  Future<ApiResult<void>> changePassword({required String current, required String next});

  Future<ApiResult<NotificationPrefs>> preferences();
  Future<ApiResult<void>> updatePreferences(NotificationPrefs prefs);

  Future<ApiResult<List<ChildProfile>>> children();
  Future<ApiResult<ChildProfile>> addChild({required String tckn, required DateTime birthDate});

  Future<ApiResult<List<DiscountType>>> discountTypes();
  Future<ApiResult<List<UserDiscount>>> discounts();
  Future<ApiResult<UserDiscount>> createDiscount(String typeId, {String? idempotencyKey});
  Future<ApiResult<void>> uploadDiscountDocument(String discountId, {required String path, required String fileName});

  Future<ApiResult<void>> uploadAvatar({required String path, required String fileName});

  /// KVKK hesap silme talebi; makbuz (talep no + süreç bitiş tarihi) döner.
  Future<ApiResult<DeleteRequestReceipt>> requestDeletion({String? reason});
  Future<ApiResult<void>> logout();
}

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._service);

  final ProfileService _service;

  @override
  Future<ApiResult<UserProfile>> me() => _service.me();

  @override
  Future<ApiResult<ProfileStats>> stats() => _service.stats();

  @override
  Future<ApiResult<ContactChallenge>> updateContact(ContactKind kind, String value) => _service.updateContact(kind, value);

  @override
  Future<ApiResult<void>> verifyContact(String challengeId, String code) => _service.verifyContact(challengeId, code);

  @override
  Future<ApiResult<void>> changePassword({required String current, required String next}) =>
      _service.changePassword(current: current, next: next);

  @override
  Future<ApiResult<NotificationPrefs>> preferences() => _service.preferences();

  @override
  Future<ApiResult<void>> updatePreferences(NotificationPrefs prefs) => _service.updatePreferences(prefs);

  @override
  Future<ApiResult<List<ChildProfile>>> children() => _service.children();

  @override
  Future<ApiResult<ChildProfile>> addChild({required String tckn, required DateTime birthDate}) =>
      _service.addChild(tckn: tckn, birthDate: birthDate);

  @override
  Future<ApiResult<List<DiscountType>>> discountTypes() => _service.discountTypes();

  @override
  Future<ApiResult<List<UserDiscount>>> discounts() => _service.discounts();

  @override
  Future<ApiResult<UserDiscount>> createDiscount(String typeId, {String? idempotencyKey}) =>
      _service.createDiscount(typeId, idempotencyKey: idempotencyKey);

  @override
  Future<ApiResult<void>> uploadDiscountDocument(String discountId, {required String path, required String fileName}) =>
      _service.uploadDiscountDocument(discountId, path: path, fileName: fileName);

  @override
  Future<ApiResult<void>> uploadAvatar({required String path, required String fileName}) =>
      _service.uploadAvatar(path: path, fileName: fileName);

  @override
  Future<ApiResult<DeleteRequestReceipt>> requestDeletion({String? reason}) => _service.requestDeletion(reason: reason);

  @override
  Future<ApiResult<void>> logout() => _service.logout();
}

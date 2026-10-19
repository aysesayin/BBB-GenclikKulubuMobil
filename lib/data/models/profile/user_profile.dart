import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/formatters.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// `GET /users/me` — oturumdaki kullanıcının profil özeti.
///
/// KVKK: TCKN sunucudan yalnız maskeli gelir (`tcknMasked`); istemci açık TCKN saklamaz.
@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    required String firstName,
    required String lastName,
    @Default('') String tcknMasked,
    @Default('') String memberNo,
    @Default(1) int level,
    @Default('') String levelName,
    @Default('') String phoneMasked,
    @Default('') String emailMasked,
    String? avatarUrl,
    DateTime? passwordChangedAt,
    @Default(0) int buanBalance,
    @Default(0) int streak,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    String first(String s) => s.isEmpty ? '' : String.fromCharCode(s.runes.first);
    return trUpper(first(firstName) + first(lastName));
  }

  /// Her durumda maskeli gösterim: sunucu yanlışlıkla açık TCKN gönderse bile maskelenir.
  String get displayTckn {
    final digits = tcknMasked.replaceAll(RegExp(r'\s'), '');
    return RegExp(r'^\d{11}$').hasMatch(digits) ? Fmt.maskTckn(digits) : tcknMasked;
  }
}

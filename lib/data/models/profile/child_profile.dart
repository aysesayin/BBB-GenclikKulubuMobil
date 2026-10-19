import 'package:freezed_annotation/freezed_annotation.dart';

part 'child_profile.freezed.dart';
part 'child_profile.g.dart';

/// `GET /users/me/children` öğesi. KVKK: ad sunucudan kısaltılmış gelir ("Deniz S. E."),
/// TCKN hiç dönmez.
@freezed
abstract class ChildProfile with _$ChildProfile {
  const factory ChildProfile({
    required String id,
    required String displayName,
    @Default('') String initial,
    required int age,

    /// Kısa durum notu (API içeriği): "2 aktif başvuru", "Yüzme kursu".
    @Default('') String note,
    @Default(true) bool mernisVerified,
  }) = _ChildProfile;

  factory ChildProfile.fromJson(Map<String, dynamic> json) => _$ChildProfileFromJson(json);
}

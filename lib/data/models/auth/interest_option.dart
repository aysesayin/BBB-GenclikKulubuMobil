import 'package:freezed_annotation/freezed_annotation.dart';

part 'interest_option.freezed.dart';
part 'interest_option.g.dart';

/// `/interests` — ilgi alanı seçeneği (panelden yönetilir).
@freezed
abstract class InterestOption with _$InterestOption {
  const factory InterestOption({
    required String id,
    required String label,

    /// İkon anahtarı (bkz. `OnbIcons.interest`).
    @Default('sparkle') String icon,

    /// Pastel karo rengi 1–6 (`palette.tile1..tile6`).
    @Default(1) int tile,
  }) = _InterestOption;

  factory InterestOption.fromJson(Map<String, dynamic> json) => _$InterestOptionFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'facility.freezed.dart';
part 'facility.g.dart';

/// Yaş kuralları — değerler API'den gelir (panelden yönetilir).
/// [minAge]–[guardianUntil] veli refakatiyle, sonrası [permissionUntil]'e kadar veli izin belgesiyle.
@freezed
abstract class AgeRules with _$AgeRules {
  const factory AgeRules({
    @Default(6) int minAge,
    @Default(15) int guardianUntil,
    @Default(17) int permissionUntil,
  }) = _AgeRules;

  factory AgeRules.fromJson(Map<String, dynamic> json) => _$AgeRulesFromJson(json);
}

/// Havuz (tesis) kartı: Fethiye, Mihraplı, Gürsu, Kestel.
@freezed
abstract class Pool with _$Pool {
  const factory Pool({
    required String id,
    required String name,
    @Default('') String district,

    /// "Olimpik", "Yarı olimpik", "Kapalı" — API içeriği.
    @Default('') String typeLabel,

    /// Pastel karo indeksi (1–6).
    @Default(3) int tile,
  }) = _Pool;

  factory Pool.fromJson(Map<String, dynamic> json) => _$PoolFromJson(json);
}

/// `GET /services/pools` — havuzlar + ortak kurallar aynı yanıtta.
@freezed
abstract class PoolCatalog with _$PoolCatalog {
  const factory PoolCatalog({
    @Default(<Pool>[]) List<Pool> items,
    @Default(AgeRules()) AgeRules ageRules,
    @Default(true) bool dailySwimConfirmation,
  }) = _PoolCatalog;

  factory PoolCatalog.fromJson(Map<String, dynamic> json) => _$PoolCatalogFromJson(json);
}

enum PriceUnit { session, term, monthly, hourly, unknown }

/// Tesis hizmet kalemi: Günlük Giriş, Yetişkin Üye, Kurs, Alt Yapı, Teknik Kurs, Engelli Saati…
@freezed
abstract class ServiceItem with _$ServiceItem {
  const ServiceItem._();

  const factory ServiceItem({
    required String id,
    required String title,
    @Default('') String facilityId,
    @Default(<String>[]) List<String> tags,
    @Default(0) num price,
    @JsonKey(unknownEnumValue: PriceUnit.unknown) @Default(PriceUnit.session) PriceUnit priceUnit,
    @Default(3) int tile,

    /// İkon anahtarı: wave, users, cap, tennis …
    @Default('wave') String icon,
  }) = _ServiceItem;

  factory ServiceItem.fromJson(Map<String, dynamic> json) => _$ServiceItemFromJson(json);

  bool get isFree => price <= 0;
}

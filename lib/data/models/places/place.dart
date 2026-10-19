import 'package:freezed_annotation/freezed_annotation.dart';

part 'place.freezed.dart';
part 'place.g.dart';

/// Galeri öğesi: görsel yoksa [tone] (pink | teal | sun) ile çizim gösterilir.
@freezed
abstract class PlaceGalleryImage with _$PlaceGalleryImage {
  const factory PlaceGalleryImage({String? url, @Default('teal') String tone, String? alt}) = _PlaceGalleryImage;

  factory PlaceGalleryImage.fromJson(Map<String, dynamic> json) => _$PlaceGalleryImageFromJson(json);
}

/// Çalışma saati satırı: "Salı – Pazar" · "10:00 – 21:00" (ya da kapalı).
@freezed
abstract class PlaceHours with _$PlaceHours {
  const factory PlaceHours({required String days, String? hours, @Default(false) bool closed}) = _PlaceHours;

  factory PlaceHours.fromJson(Map<String, dynamic> json) => _$PlaceHoursFromJson(json);
}

enum PlaceActionType {
  @JsonValue('checkin')
  checkin,
  @JsonValue('opportunity')
  opportunity,
  @JsonValue('event')
  event,
  @JsonValue('task')
  task,
  unknown,
}

/// "Burada yapabileceklerin": check-in görevi, fırsat, etkinlik…
@freezed
abstract class PlaceAction with _$PlaceAction {
  const factory PlaceAction({
    @JsonKey(unknownEnumValue: PlaceActionType.unknown) required PlaceActionType type,
    required String title,
    String? targetId,
    int? buan,
  }) = _PlaceAction;

  factory PlaceAction.fromJson(Map<String, dynamic> json) => _$PlaceActionFromJson(json);
}

/// `GET /places/{id}` (G4) — yer ya da tesis (gençlik merkezi, spor tesisi).
@freezed
abstract class PlaceDetail with _$PlaceDetail {
  const factory PlaceDetail({
    required String id,
    required String name,
    @Default('') String categoryLabel,
    @Default('') String district,

    /// place | facility
    @Default('place') String kind,
    @Default(false) bool openNow,
    @Default('') String statusLabel,
    @Default('') String description,
    String? address,
    double? lat,
    double? lng,
    @Default(<PlaceGalleryImage>[]) List<PlaceGalleryImage> gallery,
    @Default(<PlaceHours>[]) List<PlaceHours> hours,
    @Default(<String>[]) List<String> amenities,
    @Default(<PlaceAction>[]) List<PlaceAction> actions,

    /// Check-in yapılabilen yer mi (alt CTA).
    @Default(true) bool checkInEnabled,
    @Default(false) bool favorite,
  }) = _PlaceDetail;

  factory PlaceDetail.fromJson(Map<String, dynamic> json) => _$PlaceDetailFromJson(json);
}

/// `GET /places/nearby` öğesi.
@freezed
abstract class PlaceSummary with _$PlaceSummary {
  const factory PlaceSummary({
    required String id,
    required String name,
    required double lat,
    required double lng,
    @Default('') String categoryLabel,
    @Default('') String statusLabel,
    @Default(false) bool openNow,
    @Default('tile4') String tone,
    @Default('pin') String icon,

    /// Sunucunun hesapladığı mesafe (m). Konum biliniyorsa istemci yeniden hesaplar.
    int? distanceMeters,
  }) = _PlaceSummary;

  factory PlaceSummary.fromJson(Map<String, dynamic> json) => _$PlaceSummaryFromJson(json);
}

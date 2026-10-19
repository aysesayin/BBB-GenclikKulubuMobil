import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_pin.freezed.dart';
part 'map_pin.g.dart';

/// Harita katmanı (G3 segmenti). Değer API `?layer=` parametresidir.
enum MapLayer {
  @JsonValue('places')
  places,
  @JsonValue('events')
  events,
  @JsonValue('opportunities')
  opportunities;

  String get apiValue => switch (this) {
        MapLayer.places => 'places',
        MapLayer.events => 'events',
        MapLayer.opportunities => 'opportunities',
      };

  static MapLayer? tryParse(String? v) => MapLayer.values.where((l) => l.apiValue == v).firstOrNull;
}

/// Kategori çipi (Tiyatro, Sosyal, Spor…). [color] bir palette adıdır.
@freezed
abstract class MapCategory with _$MapCategory {
  const factory MapCategory({required String id, required String label, @Default('primary') String color}) = _MapCategory;

  factory MapCategory.fromJson(Map<String, dynamic> json) => _$MapCategoryFromJson(json);
}

/// Haritadaki tek nokta. [targetId] katmana göre yer / etkinlik / fırsat kimliğidir.
@freezed
abstract class MapPin with _$MapPin {
  const factory MapPin({
    required String id,
    required MapLayer layer,
    required String name,
    required double lat,
    required double lng,
    @Default('') String categoryId,
    @Default('') String subtitle,
    @Default('') String status,

    /// ok → yeşil, warn → pembe (dolu / son günler).
    @Default('ok') String statusTone,

    /// Pin rengi (palette adı); boşsa kategori rengi.
    String? color,

    /// Önizleme karosu zemini (palette adı: tile1…tile6).
    @Default('tile4') String tone,
    @Default('pin') String icon,
    String? targetId,
  }) = _MapPin;

  factory MapPin.fromJson(Map<String, dynamic> json) => _$MapPinFromJson(json);
}

/// `GET /map/pins` yanıtı.
@freezed
abstract class MapPinsData with _$MapPinsData {
  const factory MapPinsData({
    @Default(<MapCategory>[]) List<MapCategory> categories,
    @Default(<MapPin>[]) List<MapPin> pins,
  }) = _MapPinsData;

  factory MapPinsData.fromJson(Map<String, dynamic> json) => _$MapPinsDataFromJson(json);
}

/// Görünür alan (`?bbox=minLng,minLat,maxLng,maxLat`).
@immutable
class MapBounds {
  const MapBounds({required this.south, required this.west, required this.north, required this.east});

  final double south, west, north, east;

  String get query => [west, south, east, north].map((v) => v.toStringAsFixed(5)).join(',');

  @override
  bool operator ==(Object other) =>
      other is MapBounds && other.south == south && other.west == west && other.north == north && other.east == east;

  @override
  int get hashCode => Object.hash(south, west, north, east);
}

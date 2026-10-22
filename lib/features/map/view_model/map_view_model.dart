import 'package:latlong2/latlong.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/map/map_pin.dart';
import '../../../data/repositories/map_repository.dart';
import '../location/location_provider.dart';
import '../utils/pin_clustering.dart';

/// G3 · Katmanlı harita: Yerler / Etkinlikler / Fırsatlar + kategori çipleri + pin önizlemesi.
///
/// Sunucuya `?layer=&cat=&bbox=` gönderilir; mock sorgu parametrelerini yok saydığından katman ve
/// kategori filtresi istemcide de uygulanır.
class MapViewModel extends BaseViewModel {
  MapViewModel(this._repo, this._location, {MapLayer? initialLayer, String? initialCategory})
      : _layer = initialLayer ?? MapLayer.places,
        _categoryId = initialCategory;

  final MapRepository _repo;
  final LocationProvider _location;

  ViewState<MapPinsData> _state = const ViewIdle();
  ViewState<MapPinsData> get state => _state;

  MapLayer _layer;
  MapLayer get layer => _layer;

  String? _categoryId;
  String? get categoryId => _categoryId;

  String? _selectedId;
  MapBounds? _bounds;
  MapBounds? get bounds => _bounds;

  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;

  bool _locating = false;
  bool get locating => _locating;

  List<MapCategory> _categories = const [];
  List<MapCategory> get categories => _categories;

  /// Kategori çipleri varsayılan gizli; katman segmentine ilk dokunuşta (ya da rota ile
  /// kategori geldiyse) açılır.
  bool _categoriesRevealed = false;
  bool get showCategories => _categoriesRevealed || _categoryId != null;

  static const _distance = Distance();

  int _request = 0;

  Future<void> load() async {
    final id = ++_request;
    final previous = _data;
    _state = ViewLoading(previous: previous);
    notify();
    final result = await _repo.pins(layer: _layer, categoryId: _categoryId, bounds: _bounds);
    if (isDisposed || id != _request) return; // eski yanıtı yok say
    switch (result) {
      case Success(:final data, :final fromCache):
        if (data.categories.isNotEmpty) _categories = data.categories;
        _state = ViewSuccess(data, fromCache: fromCache);
      case Failure(:final error, :final cached):
        _state = ViewError(error, cached: cached ?? previous);
    }
    if (selectedPin == null) _selectedId = null;
    notify();
  }

  /// Yenileme sürerken de son veri (pinler kaybolmasın).
  MapPinsData? get _data => switch (_state) {
        ViewLoading(:final previous) => previous,
        final s => s.dataOrNull,
      };

  /// Geçerli katman + kategoriye uyan pinler.
  List<MapPin> get visiblePins {
    final cat = _categoryId;
    return (_data?.pins ?? const <MapPin>[])
        .where((p) => p.layer == _layer && (cat == null || p.categoryId == cat))
        .toList();
  }

  MapPin? get selectedPin {
    final id = _selectedId;
    if (id == null) return null;
    for (final p in visiblePins) {
      if (p.id == id) return p;
    }
    return null;
  }

  MapCategory? categoryOf(MapPin pin) {
    for (final c in _categories) {
      if (c.id == pin.categoryId) return c;
    }
    return null;
  }

  void setLayer(MapLayer layer) {
    if (!_categoriesRevealed) {
      _categoriesRevealed = true;
      notify();
    }
    if (layer == _layer) return;
    _layer = layer;
    _selectedId = null;
    load();
  }

  /// Aynı çipe tekrar dokunmak filtreyi kaldırır.
  void toggleCategory(String id) {
    _categoryId = _categoryId == id ? null : id;
    if (selectedPin == null) _selectedId = null;
    load();
  }

  /// Kullanıcının (yoksa Bursa merkezinin) en yakınındaki [count] yer pini — alt şerit.
  List<MapPin> nearestPlaces({int count = 3}) {
    final list = (_data?.pins ?? const <MapPin>[]).where((p) => p.layer == MapLayer.places).toList()
      ..sort((a, b) => distanceTo(a).compareTo(distanceTo(b)));
    return list.length <= count ? list : list.sublist(0, count);
  }

  /// Konuma (yoksa Bursa merkezine) uzaklık, metre.
  int distanceTo(MapPin pin) => _distance.as(LengthUnit.Meter, _userLocation ?? bursaCenter, LatLng(pin.lat, pin.lng)).round();

  /// Şeritten seçim: pin başka katmandaysa katman da değişir.
  void focusPin(MapPin pin) {
    if (pin.layer != _layer) {
      _layer = pin.layer;
      _selectedId = pin.id;
      load();
      return;
    }
    selectPin(pin.id);
  }

  void selectPin(String? id) {
    if (id == _selectedId) return;
    _selectedId = id;
    notify();
  }

  /// Kamera durduğunda görünür alan değiştiyse yeniden ister (görünüm debounce eder).
  void updateBounds(MapBounds bounds) {
    if (bounds == _bounds) return;
    _bounds = bounds;
    load();
  }

  Future<LocationResult> locate() async {
    if (_locating) return const LocationResult(LocationStatus.error);
    _locating = true;
    notify();
    final r = await _location.current();
    if (isDisposed) return r;
    _locating = false;
    if (r.isOk) _userLocation = r.position;
    notify();
    return r;
  }

  Future<bool> openLocationSettings() => _location.openSettings();
}

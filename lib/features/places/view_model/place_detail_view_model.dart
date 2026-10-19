import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/places/place.dart';
import '../../../data/repositories/place_repository.dart';
import '../utils/directions.dart';

/// G4 · Yer / tesis detayı (gençlik merkezi, spor tesisi, tiyatro…).
class PlaceDetailViewModel extends LoadableViewModel<PlaceDetail> {
  PlaceDetailViewModel(this._repo, this.placeId);

  final PlaceRepository _repo;
  final String placeId;

  int _galleryIndex = 0;
  int get galleryIndex => _galleryIndex;

  bool? _favorite;

  /// TODO(varsayım): Yer favorisi için uç nokta yok; şimdilik yalnız ekran içinde tutulur.
  bool get favorite => _favorite ?? state.dataOrNull?.favorite ?? false;

  int get galleryCount {
    final n = state.dataOrNull?.gallery.length ?? 0;
    return n == 0 ? 1 : n;
  }

  /// Yol tarifi adresi (konum yoksa null → buton pasif).
  Uri? get directions {
    final d = state.dataOrNull;
    return d == null ? null : directionsUri(d.lat, d.lng);
  }

  @override
  Future<ApiResult<PlaceDetail>> fetch() => _repo.detail(placeId);

  void setGalleryIndex(int i) {
    final clamped = i.clamp(0, galleryCount - 1);
    if (clamped == _galleryIndex) return;
    _galleryIndex = clamped;
    notify();
  }

  void toggleFavorite() {
    _favorite = !favorite;
    notify();
  }
}

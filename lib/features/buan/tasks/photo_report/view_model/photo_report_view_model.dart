import 'dart:typed_data';

import '../../../../../core/base/base_view_model.dart';
import '../../../../../core/network/api_result.dart';
import '../../../../../core/network/app_exception.dart';
import '../../../../../data/models/buan_tasks/photo_report.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';

typedef GeoPoint = ({double lat, double lng});

enum LocationStatus { none, loading, added, denied }

/// E12 · Çek Kazan / Fikrin ile Kazan. Fotoğraf + tür + kategori + konum + not
/// multipart gönderilir; BUAN moderasyon onayından sonra sunucuda verilir.
class PhotoReportViewModel extends LoadableViewModel<List<PhotoReportType>> {
  PhotoReportViewModel(this._repo, {required Future<GeoPoint?> Function() locate}) : _locate = locate;

  static const minIdeaLength = 10;

  final PhotoReportRepository _repo;
  final Future<GeoPoint?> Function() _locate;

  int _typeIndex = 0;
  String? _categoryId;
  String _note = '';
  Uint8List? _photo;
  String? _photoName;
  GeoPoint? _location;
  LocationStatus _locationStatus = LocationStatus.none;
  List<PhotoReport> _mine = const [];
  bool _submitting = false;
  AppException? _error;

  List<PhotoReportType> get types => state.dataOrNull ?? const [];
  PhotoReportType? get type => types.isEmpty ? null : types[_typeIndex.clamp(0, types.length - 1)];
  int get typeIndex => _typeIndex;
  String? get categoryId => _categoryId;
  String get note => _note;
  Uint8List? get photo => _photo;
  GeoPoint? get location => _location;
  LocationStatus get locationStatus => _locationStatus;
  List<PhotoReport> get mine => _mine;
  bool get submitting => _submitting;
  AppException? get error => _error;
  bool get needsPhoto => type?.requiresPhoto ?? true;

  bool get canSubmit {
    if (type == null || _categoryId == null || _submitting) return false;
    return needsPhoto ? _photo != null : _note.trim().length >= minIdeaLength;
  }

  @override
  Future<ApiResult<List<PhotoReportType>>> fetch() => _repo.types();

  @override
  bool isEmpty(List<PhotoReportType> data) => data.isEmpty;

  @override
  Future<void> load() async {
    final mine = _repo.mine();
    await super.load();
    _categoryId ??= type?.categories.firstOrNull?.id;
    if (await mine case Success(:final data)) _mine = data;
    notify();
  }

  void selectType(int i) {
    if (i == _typeIndex || i < 0 || i >= types.length) return;
    _typeIndex = i;
    _categoryId = type?.categories.firstOrNull?.id;
    notify();
  }

  void selectCategory(String id) {
    _categoryId = id;
    notify();
  }

  void setNote(String v) {
    _note = v;
    notify();
  }

  /// Fotoğraf seçilince konum da (izin varsa) eklenir.
  Future<void> setPhoto(Uint8List bytes, String name) async {
    _photo = bytes;
    _photoName = name;
    notify();
    if (_location == null) await fetchLocation();
  }

  Future<void> fetchLocation() async {
    _locationStatus = LocationStatus.loading;
    notify();
    final p = await _locate();
    if (isDisposed) return;
    _location = p;
    _locationStatus = p == null ? LocationStatus.denied : LocationStatus.added;
    notify();
  }

  /// Başarılıysa oluşan gönderiyi döndürür (görünüm onay sayfasını açar).
  Future<PhotoReport?> submit() async {
    final t = type, c = _categoryId;
    if (!canSubmit || t == null || c == null) return null;
    _submitting = true;
    notify();
    final r = await _repo.submit(
      PhotoReportDraft(
        typeId: t.id,
        categoryId: c,
        note: _note.trim(),
        photo: t.requiresPhoto ? _photo : null,
        photoName: _photoName,
        latitude: _location?.lat,
        longitude: _location?.lng,
      ),
    );
    if (isDisposed) return null;
    _submitting = false;
    PhotoReport? created;
    switch (r) {
      case Success(:final data):
        created = data;
        _mine = [data, ..._mine];
        _photo = null;
        _photoName = null;
        _note = '';
      case Failure(:final error):
        _error = error;
    }
    notify();
    return created;
  }

  void clearError() => _error = null;
}

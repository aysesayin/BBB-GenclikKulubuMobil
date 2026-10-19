import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/models/card/digital_card.dart';
import '../../../data/repositories/card_repository.dart';

enum ScanPhase { scanning, submitting, success, failure }

/// D2 · QR Okut: okunan dönen jetonu konumla birlikte `POST /buan/qr-checkin`'e gönderir.
class QrScanViewModel extends BaseViewModel {
  QrScanViewModel(this._repo, {Future<GeoPoint?> Function()? locate}) : _locate = locate ?? _noGeo;

  final CardRepository _repo;
  final Future<GeoPoint?> Function() _locate;

  static Future<GeoPoint?> _noGeo() async => null;

  ScanPhase _phase = ScanPhase.scanning;
  ScanPhase get phase => _phase;

  QrCheckInResult? _result;
  QrCheckInResult? get result => _result;

  AppException? _error;
  AppException? get error => _error;

  bool _torch = false;
  bool get torch => _torch;

  String? _lastCode;

  /// Kamera her karede aynı kodu bildirebilir → yalnız tarama fazında ve yeni kodda işlenir.
  Future<void> onCode(String? raw) async {
    final code = raw?.trim() ?? '';
    if (code.isEmpty || _phase != ScanPhase.scanning) return;
    _lastCode = code;
    _phase = ScanPhase.submitting;
    _error = null;
    notify();
    GeoPoint? geo;
    try {
      geo = await _locate();
    } on Object {
      geo = null;
    }
    final r = await _repo.checkIn(rotatingToken: code, geo: geo);
    if (isDisposed) return;
    switch (r) {
      case Success(:final data):
        _result = data;
        _phase = ScanPhase.success;
      case Failure(:final error):
        _error = error;
        _phase = ScanPhase.failure;
    }
    notify();
  }

  /// Hata sonrası aynı kodu yeniden dener.
  Future<void> retry() async {
    final c = _lastCode;
    reset();
    if (c != null) await onCode(c);
  }

  void reset() {
    _phase = ScanPhase.scanning;
    _error = null;
    _result = null;
    notify();
  }

  void setTorch(bool value) {
    _torch = value;
    notify();
  }
}

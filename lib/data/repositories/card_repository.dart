import '../../core/network/api_result.dart';
import '../../core/storage/secure_storage.dart';
import '../models/card/digital_card.dart';
import '../services/card_service.dart';

abstract interface class CardRepository {
  Future<ApiResult<DigitalCard>> card();

  /// Başarılı yanıtta 4 haneli kod çevrimdışı kullanım için güvenli depoya yazılır.
  Future<ApiResult<CardToken>> token();

  /// Son geçerli 4 haneli kod (çevrimdışı kart).
  Future<String?> lastPin();

  Future<ApiResult<QrCheckInResult>> checkIn({required String rotatingToken, GeoPoint? geo});
}

class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl(this._service, this._secure);

  final CardService _service;
  final SecureStorage _secure;

  @override
  Future<ApiResult<DigitalCard>> card() => _service.card();

  @override
  Future<ApiResult<CardToken>> token() async {
    final r = await _service.token();
    if (r case Success(:final data)) {
      try {
        await _secure.saveCardPin(data.pin);
      } on Object {
        // Güvenli depo yoksa (web/test) çevrimdışı kod yalnız bellekte kalır.
      }
    }
    return r;
  }

  @override
  Future<String?> lastPin() async {
    try {
      return await _secure.lastCardPin;
    } on Object {
      return null;
    }
  }

  @override
  Future<ApiResult<QrCheckInResult>> checkIn({required String rotatingToken, GeoPoint? geo}) =>
      _service.checkIn(rotatingToken: rotatingToken, geo: geo, idempotencyKey: 'chk-$rotatingToken');
}

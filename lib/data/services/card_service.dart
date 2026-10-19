import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/card/digital_card.dart';

/// Uzak veri kaynağı: dijital kart + QR check-in (D1–D2).
class CardService {
  CardService(this._client);

  final DioClient _client;

  /// Kart bilgisi çevrimdışı da gösterilsin diye önbelleğe alınır (token alınmaz).
  Future<ApiResult<DigitalCard>> card() =>
      _client.get(ApiEndpoints.digitalCard, parse: (d) => DigitalCard.fromJson(Json.map(d)), cacheKey: 'card');

  Future<ApiResult<CardToken>> token() => _client.get(ApiEndpoints.digitalCardToken, parse: (d) => CardToken.fromJson(Json.map(d)));

  Future<ApiResult<QrCheckInResult>> checkIn({required String rotatingToken, GeoPoint? geo, String? idempotencyKey}) => _client.post(
    ApiEndpoints.qrCheckIn,
    body: {'rotatingToken': rotatingToken, 'geo': geo?.toJson()},
    headers: idempotencyKey == null ? null : {'Idempotency-Key': idempotencyKey},
    parse: (d) => QrCheckInResult.fromJson(Json.map(d)),
  );
}

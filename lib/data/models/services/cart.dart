import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart.freezed.dart';
part 'cart.g.dart';

@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required String id,
    required String title,
    @Default('') String itemId,
    String? sessionId,
    @Default('') String facilityName,
    DateTime? start,
    @Default('') String participantName,

    /// true → katılımcı kullanıcının kendisi ("Kendim").
    @Default(false) bool forSelf,
    @Default(0) num price,
    @Default(3) int tile,
    @Default('wave') String icon,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
}

/// `GET /cart` — sunucu saatine göre rezerv bitişi ([expiresAt] & [serverTime]).
@freezed
abstract class Cart with _$Cart {
  const Cart._();

  const factory Cart({
    @Default(<CartItem>[]) List<CartItem> items,
    DateTime? expiresAt,
    DateTime? serverTime,
    @Default(5) int holdMinutes,
  }) = _Cart;

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);

  num get subtotal => items.fold<num>(0, (s, i) => s + i.price);
}

/// `POST /cart/hold` yanıtı: kontenjan rezervi.
@freezed
abstract class CartHold with _$CartHold {
  const factory CartHold({
    required String cartItemId,
    required DateTime expiresAt,
    DateTime? serverTime,
  }) = _CartHold;

  factory CartHold.fromJson(Map<String, dynamic> json) => _$CartHoldFromJson(json);
}

enum CheckoutStatus { paid, pending3ds, failed, unknown }

/// `POST /cart/checkout` yanıtı. [paymentUrl] → 3D Secure sayfası.
@freezed
abstract class CheckoutResult with _$CheckoutResult {
  const factory CheckoutResult({
    required String orderId,
    String? paymentUrl,
    @JsonKey(unknownEnumValue: CheckoutStatus.unknown) @Default(CheckoutStatus.pending3ds) CheckoutStatus status,
  }) = _CheckoutResult;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) => _$CheckoutResultFromJson(json);
}

/// Sepet + cihaz saatine çevrilmiş rezerv bitişi.
class CartSnapshot {
  const CartSnapshot({required this.cart, required this.deadline});

  final Cart cart;

  /// Sunucu/cihaz saat farkı düzeltilmiş bitiş anı. null → rezerv yok.
  final DateTime? deadline;
}

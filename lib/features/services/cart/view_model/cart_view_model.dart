import 'dart:math' as math;

import '../../../../core/base/base_view_model.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../data/models/services/benefits.dart';
import '../../../../data/models/services/cart.dart';
import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/services/cart_payment_launcher.dart';

enum HoldPhase { none, active, low, expired }

/// Sepet ekranının tüm verisi (sepet + indirimler + kupon bakiyesi).
class CartData {
  const CartData({required this.snapshot, this.discounts = const [], this.wallet = const CouponWallet()});

  final CartSnapshot snapshot;
  final List<EligibleDiscount> discounts;
  final CouponWallet wallet;

  Cart get cart => snapshot.cart;

  CartData withSnapshot(CartSnapshot s) => CartData(snapshot: s, discounts: discounts, wallet: wallet);
}

class CheckoutOutcome {
  const CheckoutOutcome(this.kind, {this.error});

  final PaymentOutcome kind;
  final AppException? error;
}

/// H3 · Sepet: 5 dk rezerv sayacı (sunucu saatine göre), indirim/kupon, toplamlar, ödeme.
class CartViewModel extends LoadableViewModel<CartData> {
  CartViewModel(this._repo, {required PaymentLauncher payment, Clock? now, this.lowThreshold = const Duration(seconds: 60)})
      : _payment = payment,
        _now = now ?? DateTime.now;

  final CartRepository _repo;
  final PaymentLauncher _payment;
  final Clock _now;
  final Duration lowThreshold;

  String? _discountId;
  bool _discountTouched = false;
  bool _useCoupon = false;
  bool _couponTouched = false;
  bool _expired = false;
  bool _paying = false;
  String? _idempotencyKey;

  Cart? get cart => state.dataOrNull?.cart;
  List<EligibleDiscount> get discounts => state.dataOrNull?.discounts ?? const [];
  CouponWallet get wallet => state.dataOrNull?.wallet ?? const CouponWallet();
  DateTime? get deadline => state.dataOrNull?.snapshot.deadline;
  bool get expired => _expired;
  bool get paying => _paying;
  String? get discountId => _discountId;
  bool get useCoupon => _useCoupon;
  DateTime now() => _now();

  @override
  Future<ApiResult<CartData>> fetch() async {
    final results = await Future.wait<Object>([_repo.cart(), _repo.discounts(), _repo.coupons()]);
    final cart = results[0] as ApiResult<CartSnapshot>;
    final discounts = (results[1] as ApiResult<List<EligibleDiscount>>).dataOrNull ?? const <EligibleDiscount>[];
    final wallet = (results[2] as ApiResult<CouponWallet>).dataOrNull ?? const CouponWallet();
    return cart.map((s) => CartData(snapshot: s, discounts: discounts, wallet: wallet));
  }

  @override
  bool isEmpty(CartData data) => data.cart.items.isEmpty && !_expired;

  @override
  Future<void> load() async {
    await super.load();
    final data = state.dataOrNull;
    if (data == null || isDisposed) return;
    if (!_discountTouched || !data.discounts.any((d) => d.id == _discountId && d.usable)) {
      _discountId = data.discounts.where((d) => d.usable).firstOrNull?.id;
    }
    if (!_couponTouched) _useCoupon = data.wallet.balance > 0;
    checkExpiry();
    notify();
  }

  // ---- Rezerv sayacı ----
  Duration get remaining {
    final d = deadline;
    if (d == null) return Duration.zero;
    final left = d.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  HoldPhase get phase {
    if (_expired) return HoldPhase.expired;
    if (deadline == null) return HoldPhase.none;
    final left = remaining;
    if (left == Duration.zero) return HoldPhase.expired;
    return left <= lowThreshold ? HoldPhase.low : HoldPhase.active;
  }

  /// Halka için 0–1 (tam süre = sunucunun bildirdiği rezerv dakikası).
  double get holdProgress {
    final total = Duration(minutes: cart?.holdMinutes ?? 5).inMilliseconds;
    return total == 0 ? 0 : (remaining.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Sayaç tıklarında ve uygulama öne geldiğinde çağrılır; süre bittiyse sepeti boşaltır.
  void checkExpiry() {
    final d = deadline;
    if (_expired || d == null || _now().isBefore(d)) return;
    _expired = true;
    final data = state.dataOrNull;
    if (data != null) {
      state = ViewSuccess(data.withSnapshot(CartSnapshot(cart: data.cart.copyWith(items: const []), deadline: d)));
    } else {
      notify();
    }
    _repo.clear();
  }

  /// Arka plandan dönüşte sunucu süresiyle yeniden eşitle.
  Future<void> resync() async {
    if (_expired || state.dataOrNull == null) return;
    checkExpiry();
    if (_expired) return;
    final r = await _repo.cart();
    final current = state.dataOrNull;
    if (isDisposed || _expired || current == null) return;
    if (r case Success(:final data) when data.cart.items.isNotEmpty) {
      state = ViewSuccess(current.withSnapshot(data));
    }
    checkExpiry();
  }

  // ---- İndirim / kupon ----
  void selectDiscount(String? id) {
    if (id != null && !discounts.any((d) => d.id == id && d.usable)) return;
    _discountTouched = true;
    _discountId = id;
    notify();
  }

  void setUseCoupon({required bool value}) {
    _couponTouched = true;
    _useCoupon = value && wallet.balance > 0;
    notify();
  }

  num get subtotal => cart?.subtotal ?? 0;

  int get discountRate => discounts.where((d) => d.id == _discountId).firstOrNull?.rate ?? 0;

  num get discountAmount => _round(subtotal * discountRate / 100);

  num get couponAmount => _useCoupon ? _round(math.min(wallet.balance, subtotal - discountAmount)) : 0;

  num get total => _round(math.max(0, subtotal - discountAmount - couponAmount));

  static num _round(num v) => (v * 100).round() / 100;

  bool get canPay => !_expired && !_paying && (cart?.items.isNotEmpty ?? false);

  // ---- Ödeme ----
  Future<CheckoutOutcome> checkout() async {
    if (!canPay) return const CheckoutOutcome(PaymentOutcome.failed);
    _paying = true;
    notify();
    final key = _idempotencyKey ??= 'chk-${_now().microsecondsSinceEpoch}';
    final r = await _repo.checkout(discountId: _discountId, useCoupon: _useCoupon, idempotencyKey: key);
    if (isDisposed) return const CheckoutOutcome(PaymentOutcome.failed);
    final outcome = switch (r) {
      Failure(:final error) => CheckoutOutcome(PaymentOutcome.failed, error: error),
      Success(:final data) when data.status == CheckoutStatus.paid => const CheckoutOutcome(PaymentOutcome.success),
      Success(:final data) when data.paymentUrl != null => CheckoutOutcome(await _payment.open(data.paymentUrl!)),
      Success() => const CheckoutOutcome(PaymentOutcome.failed),
    };
    if (isDisposed) return outcome;
    if (outcome.kind != PaymentOutcome.failed) _idempotencyKey = null;
    _paying = false;
    notify();
    return outcome;
  }
}

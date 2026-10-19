import 'dart:math';

import '../../../../core/base/base_view_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../data/models/buan/buan_reward.dart';
import '../../../../data/repositories/buan_repository.dart';

/// E3 · Ödül detayı + takas.
///
/// Idempotency: onay sheet'i her açıldığında yeni bir anahtar üretilir ve aynı
/// sheet içindeki tüm denemelerde (ağ hatası sonrası "Onayla"ya tekrar basma)
/// AYNI anahtar gönderilir; böylece sunucu çift düşüm yapmaz.
class RewardDetailViewModel extends LoadableViewModel<BuanReward> {
  RewardDetailViewModel(this._repo, this.rewardId, {String Function()? keyFactory}) : _newKey = keyFactory ?? _uuidV4 {
    _repo.balance.addListener(notify);
  }

  final BuanRepository _repo;
  final String rewardId;
  final String Function() _newKey;

  String? _idempotencyKey;
  bool _redeeming = false;
  AppException? _redeemError;
  BuanRedeemResult? _result;
  int? _balanceBefore;

  int get balance => _repo.balance.value ?? 0;
  BuanReward? get reward => state.dataOrNull;
  int get balanceAfter => balance - (reward?.price ?? 0);
  bool get canAfford => reward != null && reward!.price <= balance;
  int get missing => max(0, (reward?.price ?? 0) - balance);
  bool get soldOut => reward?.soldOut ?? false;
  bool get canRedeem => reward != null && canAfford && !soldOut;

  bool get redeeming => _redeeming;
  AppException? get redeemError => _redeemError;
  BuanRedeemResult? get result => _result;

  /// Takas öncesi / sonrası bakiye (başarı ekranında 600 ms sayım).
  int get balanceBefore => _balanceBefore ?? balance;
  String? get idempotencyKey => _idempotencyKey;

  @override
  Future<ApiResult<BuanReward>> fetch() async {
    final reward = _repo.reward(rewardId);
    if (_repo.balance.value == null) await _repo.wallet();
    return reward;
  }

  /// Onay sheet'i açılırken çağrılır.
  void beginRedeem() {
    _idempotencyKey = _newKey();
    _redeemError = null;
    notify();
  }

  /// Sheet kapatıldı (Vazgeç). Sonraki açılış yeni anahtar alır.
  void cancelRedeem() {
    if (_redeeming) return;
    _idempotencyKey = null;
    _redeemError = null;
    notify();
  }

  /// true → başarılı; [result] dolar, paylaşılan bakiye güncellenir.
  Future<bool> redeem() async {
    final r = reward;
    if (r == null || _redeeming || !canRedeem) return false;
    final key = _idempotencyKey ??= _newKey();
    final before = balance;
    _redeeming = true;
    _redeemError = null;
    notify();
    final res = await _repo.redeem(r, idempotencyKey: key);
    if (isDisposed) return false;
    _redeeming = false;
    switch (res) {
      case Success(:final data):
        _balanceBefore = before;
        _result = data;
        _idempotencyKey = null;
        notify();
        return true;
      case Failure(:final error):
        _redeemError = error;
        notify();
        return false;
    }
  }

  static String _uuidV4() {
    final rnd = Random.secure();
    final b = List<int>.generate(16, (_) => rnd.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  @override
  void dispose() {
    _repo.balance.removeListener(notify);
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../../core/network/api_result.dart';
import '../models/buan/buan_badge.dart';
import '../models/buan/buan_league.dart';
import '../models/buan/buan_reward.dart';
import '../models/buan/buan_task.dart';
import '../models/buan/buan_transaction.dart';
import '../models/buan/buan_wallet.dart';
import '../services/buan_service.dart';

/// BUAN çekirdeği: cüzdan, seviye, seri, görevler, pazar, lig, rozetler, geçmiş.
///
/// [balance] tüm BUAN ekranlarının paylaştığı son bilinen bakiyedir; cüzdan
/// okunduğunda ve takas başarılı olduğunda güncellenir (ana ekran eski → yeni sayar).
abstract interface class BuanRepository {
  ValueListenable<int?> get balance;

  Future<ApiResult<BuanWallet>> wallet();
  Future<ApiResult<BuanLevel>> level();
  Future<ApiResult<BuanStreak>> streak();
  Future<ApiResult<List<BuanTaskGroup>>> tasks();
  Future<ApiResult<BuanTransactionPage>> transactions({BuanTxFilter filter = BuanTxFilter.all, String? cursor});
  Future<ApiResult<BuanMarket>> market();
  Future<ApiResult<BuanReward>> reward(String id);
  Future<ApiResult<BuanRedeemResult>> redeem(BuanReward reward, {required String idempotencyKey});
  Future<ApiResult<BuanLeague>> leaderboard({BuanLeagueScope scope = BuanLeagueScope.global, String? districtId});
  Future<ApiResult<List<BuanBadge>>> badges();
}

class BuanRepositoryImpl implements BuanRepository {
  BuanRepositoryImpl(this._service);

  final BuanService _service;
  final ValueNotifier<int?> _balance = ValueNotifier<int?>(null);

  @override
  ValueListenable<int?> get balance => _balance;

  @override
  Future<ApiResult<BuanWallet>> wallet() async {
    final r = await _service.wallet();
    if (r case Success(:final data)) _balance.value = data.balance;
    return r;
  }

  @override
  Future<ApiResult<BuanLevel>> level() => _service.level();

  @override
  Future<ApiResult<BuanStreak>> streak() => _service.streak();

  @override
  Future<ApiResult<List<BuanTaskGroup>>> tasks() => _service.tasks();

  @override
  Future<ApiResult<BuanTransactionPage>> transactions({BuanTxFilter filter = BuanTxFilter.all, String? cursor}) =>
      _service.transactions(filter: filter, cursor: cursor);

  @override
  Future<ApiResult<BuanMarket>> market() => _service.market();

  @override
  Future<ApiResult<BuanReward>> reward(String id) => _service.reward(id);

  @override
  Future<ApiResult<BuanRedeemResult>> redeem(BuanReward reward, {required String idempotencyKey}) async {
    final before = _balance.value;
    final r = await _service.redeem(reward.id, idempotencyKey: idempotencyKey);
    if (r case Success(:final data)) {
      final next = data.balance ?? (before == null ? null : before - reward.price);
      if (next != null) _balance.value = next;
    }
    return r;
  }

  @override
  Future<ApiResult<BuanLeague>> leaderboard({BuanLeagueScope scope = BuanLeagueScope.global, String? districtId}) =>
      _service.leaderboard(scope: scope, districtId: districtId);

  @override
  Future<ApiResult<List<BuanBadge>>> badges() => _service.badges();
}

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/buan/buan_badge.dart';
import '../models/buan/buan_league.dart';
import '../models/buan/buan_reward.dart';
import '../models/buan/buan_task.dart';
import '../models/buan/buan_transaction.dart';
import '../models/buan/buan_wallet.dart';

/// Uzak veri kaynağı: BUAN cüzdan, görev listesi, pazar, lig, rozet, geçmiş.
class BuanService {
  BuanService(this._client);

  final DioClient _client;

  Future<ApiResult<BuanWallet>> wallet() =>
      _client.get(ApiEndpoints.buanWallet, parse: (d) => BuanWallet.fromJson(Json.map(d)), cacheKey: 'buan.wallet');

  Future<ApiResult<BuanLevel>> level() =>
      _client.get(ApiEndpoints.buanLevel, parse: (d) => BuanLevel.fromJson(Json.map(d)), cacheKey: 'buan.level');

  Future<ApiResult<BuanStreak>> streak() =>
      _client.get(ApiEndpoints.streak, parse: (d) => BuanStreak.fromJson(Json.map(d)), cacheKey: 'buan.streak');

  Future<ApiResult<List<BuanTaskGroup>>> tasks() =>
      _client.get(ApiEndpoints.buanTasks, parse: (d) => Json.list(Json.map(d)['groups'], BuanTaskGroup.fromJson), cacheKey: 'buan.tasks');

  Future<ApiResult<BuanTransactionPage>> transactions({required BuanTxFilter filter, String? cursor}) => _client.get(
    ApiEndpoints.buanTransactions,
    query: {'type': filter.name, 'cursor': ?cursor},
    parse: (d) => BuanTransactionPage.fromJson(Json.map(d)),
    cacheKey: cursor == null ? 'buan.transactions' : null,
  );

  Future<ApiResult<BuanMarket>> market() =>
      _client.get(ApiEndpoints.buanRewards, parse: (d) => BuanMarket.fromJson(Json.map(d)), cacheKey: 'buan.market');

  Future<ApiResult<BuanReward>> reward(String id) =>
      _client.get(ApiEndpoints.rewardDetail(id), parse: (d) => BuanReward.fromJson(Json.map(d)), cacheKey: 'buan.reward.$id');

  /// Takas. Aynı [idempotencyKey] ile tekrar deneme sunucuda çift düşüm yapmaz.
  Future<ApiResult<BuanRedeemResult>> redeem(String id, {required String idempotencyKey}) => _client.post(
    ApiEndpoints.redeemReward(id),
    headers: {'Idempotency-Key': idempotencyKey},
    parse: (d) => BuanRedeemResult.fromJson(Json.map(d)),
  );

  Future<ApiResult<BuanLeague>> leaderboard({required BuanLeagueScope scope, String? districtId}) => _client.get(
    ApiEndpoints.leaderboard,
    query: {'scope': scope.name, 'district': ?districtId},
    parse: (d) => BuanLeague.fromJson(Json.map(d)),
    cacheKey: 'buan.league',
  );

  Future<ApiResult<List<BuanBadge>>> badges() =>
      _client.get(ApiEndpoints.badges, parse: (d) => Json.list(d, BuanBadge.fromJson), cacheKey: 'buan.badges');
}

import 'dart:async';
import 'dart:math';

import '../../core/network/api_result.dart';
import '../models/opportunities/claim.dart';
import '../models/opportunities/opportunity.dart';
import '../services/opportunity_service.dart';

/// Ekranlar arası senkron (detayda favori → listede kalp, yakalama → cüzdan sayacı).
sealed class OpportunityEvent {
  const OpportunityEvent(this.id);
  final String id;
}

final class FavoriteChanged extends OpportunityEvent {
  const FavoriteChanged(super.id, {required this.isFavorite});
  final bool isFavorite;
}

final class OpportunityClaimed extends OpportunityEvent {
  OpportunityClaimed(this.result) : super(result.opportunityId);
  final ClaimResult result;
}

abstract interface class OpportunityRepository {
  Stream<OpportunityEvent> get events;

  Future<ApiResult<List<Opportunity>>> list({String? category, OpportunityFilter? filter, int page = 1});
  Future<ApiResult<List<OpportunityCategory>>> categories();
  Future<ApiResult<OpportunityDetail>> detail(String id);
  Future<ApiResult<void>> setFavorite(String id, {required bool value});
  Future<ApiResult<ClaimResult>> claim(String id);
  Future<ApiResult<List<WalletItem>>> mine();
}

class OpportunityRepositoryImpl implements OpportunityRepository {
  OpportunityRepositoryImpl(this._service);

  final OpportunityService _service;
  final _events = StreamController<OpportunityEvent>.broadcast();
  final _rnd = Random();

  /// Aynı fırsat için tekrar basışta aynı anahtar → sunucu tek kod üretir.
  final _claimKeys = <String, String>{};

  @override
  Stream<OpportunityEvent> get events => _events.stream;

  @override
  Future<ApiResult<List<Opportunity>>> list({String? category, OpportunityFilter? filter, int page = 1}) =>
      _service.list(category: category, filter: filter, page: page);

  @override
  Future<ApiResult<List<OpportunityCategory>>> categories() => _service.categories();

  @override
  Future<ApiResult<OpportunityDetail>> detail(String id) => _service.detail(id);

  @override
  Future<ApiResult<void>> setFavorite(String id, {required bool value}) async {
    final r = await _service.setFavorite(id, value: value);
    if (r is Success) _events.add(FavoriteChanged(id, isFavorite: value));
    return r;
  }

  @override
  Future<ApiResult<ClaimResult>> claim(String id) async {
    final key = _claimKeys[id] ??= '$id-${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(1 << 32)}';
    final r = await _service.claim(id, idempotencyKey: key);
    if (r case Success(:final data)) {
      _claimKeys.remove(id);
      _events.add(OpportunityClaimed(data));
    }
    return r;
  }

  @override
  Future<ApiResult<List<WalletItem>>> mine() => _service.mine();
}

import 'package:flutter/material.dart';

import '../../../../core/base/base_view_model.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/network/api_result.dart';
import '../../../../data/models/buan/buan_transaction.dart';
import '../../../../data/repositories/buan_repository.dart';

/// Gün başlığı altında toplanmış işlemler.
typedef HistoryDay = ({DateTime day, List<BuanTransaction> items});

/// E6 · Geçmiş İşlemlerim: filtre segmenti + imleçli sayfalama.
/// Filtre sunucuya `type` olarak gider ve (mock için) istemcide de uygulanır.
class HistoryViewModel extends BaseViewModel {
  HistoryViewModel(this._repo);

  final BuanRepository _repo;

  ViewState<List<BuanTransaction>> _state = const ViewIdle();
  ViewState<List<BuanTransaction>> get state => _state;

  BuanTxFilter _filter = BuanTxFilter.all;
  BuanTxFilter get filter => _filter;

  BuanMonthSummary? _summary;
  BuanMonthSummary? get summary => _summary;

  String? _cursor;
  bool get hasMore => _cursor != null;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  int _generation = 0;

  Future<void> load() async {
    final gen = ++_generation;
    _state = ViewLoading(previous: _state.dataOrNull);
    notify();
    final res = await _repo.transactions(filter: _filter);
    if (isDisposed || gen != _generation) return;
    switch (res) {
      case Success(:final data, :final fromCache):
        _summary = data.summary ?? _summary;
        _cursor = data.nextCursor;
        final items = _apply(data.items);
        _state = items.isEmpty ? const ViewEmpty() : ViewSuccess(items, fromCache: fromCache);
      case Failure(:final error):
        _state = ViewError(error, cached: _state.dataOrNull);
    }
    notify();
  }

  Future<void> refresh() => load();

  Future<void> setFilter(BuanTxFilter f) async {
    if (f == _filter) return;
    _filter = f;
    _cursor = null;
    _state = const ViewIdle();
    await load();
  }

  /// Liste sonuna yaklaşınca çağrılır.
  Future<void> loadMore() async {
    final current = _state;
    final cursor = _cursor;
    if (_loadingMore || cursor == null || current is! ViewSuccess<List<BuanTransaction>>) return;
    final gen = _generation;
    _loadingMore = true;
    notify();
    final res = await _repo.transactions(filter: _filter, cursor: cursor);
    if (isDisposed || gen != _generation) return;
    _loadingMore = false;
    if (res case Success(:final data)) {
      _cursor = data.nextCursor == cursor ? null : data.nextCursor;
      final seen = current.data.map((t) => t.id).toSet();
      final more = _apply(data.items).where((t) => !seen.contains(t.id));
      _state = ViewSuccess([...current.data, ...more]);
    }
    notify();
  }

  List<BuanTransaction> _apply(List<BuanTransaction> items) => switch (_filter) {
    BuanTxFilter.all => items,
    BuanTxFilter.earn => items.where((t) => t.isEarn).toList(),
    BuanTxFilter.spend => items.where((t) => !t.isEarn).toList(),
  };

  /// İşlemleri yerel güne göre gruplar (sıra korunur).
  static List<HistoryDay> groupByDay(List<BuanTransaction> items) {
    final out = <HistoryDay>[];
    for (final t in items) {
      final day = DateUtils.dateOnly(t.createdAt.toLocal());
      if (out.isNotEmpty && out.last.day == day) {
        out.last.items.add(t);
      } else {
        out.add((day: day, items: [t]));
      }
    }
    return out;
  }
}

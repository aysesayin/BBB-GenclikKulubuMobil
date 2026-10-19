import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../data/repositories/opportunity_repository.dart';

/// C1 · Fırsat listesi: kategori + filtre + sonsuz kaydırma + iyimser favori.
///
/// Mock modu sorgu parametrelerini yok saydığı için filtreler istemcide de uygulanır.
class OpportunityListViewModel extends BaseViewModel {
  OpportunityListViewModel(this._repo, {required this.isMember, DateTime Function()? clock}) : _now = clock ?? DateTime.now {
    _sub = _repo.events.listen(_onEvent);
  }

  final OpportunityRepository _repo;
  final bool isMember;
  final DateTime Function() _now;
  late final StreamSubscription<OpportunityEvent> _sub;

  ViewState<List<Opportunity>> _state = const ViewIdle();
  ViewState<List<Opportunity>> get state => _state;

  List<Opportunity> _items = const [];
  List<OpportunityCategory> _categories = const [];
  List<OpportunityCategory> get categories => _categories;

  /// null → "Tümü".
  String? _category;
  String? get category => _category;

  OpportunityFilter? _filter;
  OpportunityFilter? get filter => _filter;

  int _page = 1;
  int _gen = 0;
  bool _hasMore = false;
  bool get hasMore => _hasMore;
  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;
  bool _loadMoreFailed = false;
  bool get loadMoreFailed => _loadMoreFailed;
  int? _total;

  /// Cüzdandaki aktif kod sayısı ("Cüzdan · 3"); misafirde null.
  int? _walletCount;
  int? get walletCount => _walletCount;

  /// Filtre uygulanmış, görünen liste.
  List<Opportunity> get visible {
    final now = _now();
    var list = _items.where((o) => _category == null || o.categoryId == _category);
    list = switch (_filter) {
      null => list,
      OpportunityFilter.newest => list.where((o) => o.isNew),
      OpportunityFilter.ending => list.where((o) => o.isEndingSoon(now)),
      OpportunityFilter.favorites => list.where((o) => o.isFavorite),
      OpportunityFilter.nearby => list.where((o) => o.distanceMeters != null),
    };
    final out = list.toList();
    if (_filter == OpportunityFilter.nearby) out.sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));
    return out;
  }

  /// Başlıktaki "N fırsat": sunucu daha fazlasını söylüyorsa onu, yoksa görüneni gösterir.
  int get count => _hasMore && _total != null ? _total! : visible.length;

  bool get isEmpty => _state.dataOrNull != null && visible.isEmpty;

  Future<void> load() async {
    final gen = ++_gen;
    _state = ViewLoading(previous: _state.dataOrNull);
    _loadMoreFailed = false;
    notify();
    if (_categories.isEmpty) unawaited(_loadCategories());
    if (isMember) unawaited(refreshWallet());
    final r = await _repo.list(category: _category, filter: _filter, page: 1);
    if (isDisposed || gen != _gen) return;
    switch (r) {
      case Success(:final data, :final meta, :final fromCache):
        _items = _dedupe(data);
        _page = 1;
        _hasMore = !fromCache && (meta?.hasMore ?? false);
        _total = meta?.total;
        _state = ViewSuccess(_items, fromCache: fromCache);
      case Failure(:final error, :final cached):
        if (cached != null) _items = cached;
        _hasMore = false;
        _state = ViewError(error, cached: cached);
    }
    notify();
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || _state is! ViewSuccess) return;
    final gen = _gen;
    _loadingMore = true;
    _loadMoreFailed = false;
    notify();
    final r = await _repo.list(category: _category, filter: _filter, page: _page + 1);
    if (isDisposed || gen != _gen) return;
    switch (r) {
      case Success(:final data, :final meta):
        _page++;
        _items = _dedupe([..._items, ...data]);
        _hasMore = (meta?.hasMore ?? false) && data.isNotEmpty;
        _total = meta?.total ?? _total;
        _state = ViewSuccess(_items);
      case Failure():
        _loadMoreFailed = true;
    }
    _loadingMore = false;
    notify();
  }

  void selectCategory(String? id) {
    if (id == _category) return;
    _category = id;
    load();
  }

  /// Seçili filtreye tekrar dokunmak filtreyi kaldırır.
  void toggleFilter(OpportunityFilter f) {
    _filter = _filter == f ? null : f;
    load();
  }

  void clearFilters() {
    _filter = null;
    _category = null;
    load();
  }

  /// İyimser favori: önce arayüz, hata olursa geri alınır ve hata döner.
  Future<AppException?> toggleFavorite(String id) async {
    final current = _items.where((o) => o.id == id).firstOrNull;
    if (current == null) return null;
    final value = !current.isFavorite;
    _setFavorite(id, value);
    final r = await _repo.setFavorite(id, value: value);
    if (r case Failure(:final error)) {
      _setFavorite(id, !value);
      return error;
    }
    return null;
  }

  Future<void> refreshWallet() async {
    if (!isMember) return;
    final r = await _repo.mine();
    if (isDisposed) return;
    if (r case Success(:final data)) {
      _walletCount = data.where((w) => w.status == WalletStatus.active).length;
      notify();
    }
  }

  Future<void> _loadCategories() async {
    final r = await _repo.categories();
    if (isDisposed) return;
    if (r case Success(:final data)) {
      _categories = data;
      notify();
    }
  }

  void _onEvent(OpportunityEvent e) {
    switch (e) {
      case FavoriteChanged(:final id, :final isFavorite):
        _setFavorite(id, isFavorite);
      case OpportunityClaimed():
        refreshWallet();
    }
  }

  void _setFavorite(String id, bool value) {
    if (!_items.any((o) => o.id == id && o.isFavorite != value)) return;
    _items = [for (final o in _items) o.id == id ? o.copyWith(isFavorite: value) : o];
    if (_state is ViewSuccess<List<Opportunity>>) {
      _state = ViewSuccess(_items, fromCache: (_state as ViewSuccess<List<Opportunity>>).fromCache);
    }
    notify();
  }

  static List<Opportunity> _dedupe(List<Opportunity> list) {
    final seen = <String>{};
    return [
      for (final o in list)
        if (seen.add(o.id)) o,
    ];
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @visibleForTesting
  List<Opportunity> get items => _items;
}

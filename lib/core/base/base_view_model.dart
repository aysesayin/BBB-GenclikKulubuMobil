import 'package:flutter/foundation.dart';

import '../network/api_result.dart';
import 'view_state.dart';

/// Tüm ViewModel'lerin tabanı. UI durumu + güvenli notify.
abstract class BaseViewModel extends ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  /// dispose sonrası gelen async yanıtlarda hata vermeden notify eder.
  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Tek bir ana veri kaynağı yükleyen ekranlar için kısayol.
abstract class LoadableViewModel<T> extends BaseViewModel {
  ViewState<T> _state = const ViewIdle();
  ViewState<T> get state => _state;

  @protected
  set state(ViewState<T> value) {
    _state = value;
    notify();
  }

  /// Alt sınıf veriyi getirir.
  @protected
  Future<ApiResult<T>> fetch();

  /// Boş kabul edilecek veri (ör. liste boş). Varsayılan: hiçbir zaman.
  @protected
  bool isEmpty(T data) => false;

  Future<void> load() async {
    state = ViewLoading(previous: _state.dataOrNull);
    final result = await fetch();
    if (isDisposed) return;
    state = switch (result) {
      Success(:final data, :final fromCache) => isEmpty(data) ? const ViewEmpty() : ViewSuccess(data, fromCache: fromCache),
      Failure(:final error, :final cached) => ViewError(error, cached: cached),
    };
  }

  Future<void> refresh() => load();
}

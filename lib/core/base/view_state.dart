import '../network/app_exception.dart';

/// Ekran durumu. Tüm ana ekranlar aynı 4 durum kalıbını kullanır (tasarım S1–S4):
/// skeleton (loading) · boş (empty) · hata/çevrimdışı (error) · içerik (success).
sealed class ViewState<T> {
  const ViewState();

  bool get isLoading => this is ViewLoading<T>;

  /// [dataOrNull] + yenileme sırasında eski içerik (ViewLoading.previous).
  T? get dataOrPrevious => switch (this) {
        ViewLoading<T>(:final previous) => previous,
        _ => dataOrNull,
      };
  T? get dataOrNull => switch (this) {
        ViewSuccess<T>(:final data) => data,
        ViewError<T>(:final cached) => cached,
        _ => null,
      };
}

final class ViewIdle<T> extends ViewState<T> {
  const ViewIdle();
}

final class ViewLoading<T> extends ViewState<T> {
  const ViewLoading({this.previous});

  /// Yenileme sırasında eski içerik gösterilmeye devam edebilir.
  final T? previous;
}

final class ViewSuccess<T> extends ViewState<T> {
  const ViewSuccess(this.data, {this.fromCache = false});
  final T data;

  /// true → "Çevrimdışısın · kayıtlı içerik gösteriliyor" şeridi.
  final bool fromCache;
}

final class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

final class ViewError<T> extends ViewState<T> {
  const ViewError(this.error, {this.cached});
  final AppException error;
  final T? cached;

  bool get isOffline => error is NetworkException;
}

import 'app_exception.dart';

/// Repository dönüş tipi. ViewModel'ler `switch` ile ele alır:
/// ```dart
/// switch (await repo.wallet()) {
///   case Success(:final data): ...
///   case Failure(:final error): ...
/// }
/// ```
sealed class ApiResult<T> {
  const ApiResult();

  R when<R>({required R Function(T data) success, required R Function(AppException error) failure}) =>
      switch (this) {
        Success<T>(:final data) => success(data),
        Failure<T>(:final error) => failure(error),
      };

  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  ApiResult<R> map<R>(R Function(T data) f) => switch (this) {
        Success<T>(:final data, :final meta, :final fromCache) => Success(f(data), meta: meta, fromCache: fromCache),
        Failure<T>(:final error, :final cached) => Failure(error, cached: cached == null ? null : f(cached)),
      };
}

final class Success<T> extends ApiResult<T> {
  const Success(this.data, {this.meta, this.fromCache = false});
  final T data;
  final PageMeta? meta;

  /// true → çevrimdışıyken önbellekten geldi (UI üst şerit gösterir).
  final bool fromCache;
}

final class Failure<T> extends ApiResult<T> {
  const Failure(this.error, {this.cached});
  final AppException error;

  /// Hata durumunda gösterilebilecek son önbellek verisi.
  final T? cached;
}

/// Standart zarfın `meta` alanı.
class PageMeta {
  const PageMeta({required this.page, required this.pageSize, required this.total});

  factory PageMeta.fromJson(Map<String, dynamic> j) => PageMeta(
        page: (j['page'] as num?)?.toInt() ?? 1,
        pageSize: (j['pageSize'] as num?)?.toInt() ?? 20,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );

  final int page, pageSize, total;
  bool get hasMore => page * pageSize < total;
}

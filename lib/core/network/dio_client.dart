import 'dart:convert';

import 'package:dio/dio.dart';

import '../storage/cache_store.dart';
import 'api_endpoints.dart';
import 'api_result.dart';
import 'app_exception.dart';

typedef JsonParser<T> = T Function(Object? data);

/// Dio sarmalayıcı: standart zarfı çözer, hatayı [AppException]'a çevirir,
/// isteğe bağlı olarak yanıtı çevrimdışı kullanım için önbelleğe yazar.
///
/// Zarf: `{ "success": bool, "data": ..., "message": string, "errors": [], "meta": {page,pageSize,total} }`
class DioClient {
  DioClient({required Dio dio, required CacheStore cache})
      : _dio = dio,
        _cache = cache;

  final Dio _dio;
  final CacheStore _cache;

  Dio get raw => _dio;

  static BaseOptions baseOptions() => BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      );

  /// [cacheKey] verilirse başarılı yanıt saklanır; ağ hatasında saklı veri
  /// `Success(fromCache: true)` olarak döner.
  Future<ApiResult<T>> get<T>(
    String path, {
    required JsonParser<T> parse,
    Map<String, dynamic>? query,
    String? cacheKey,
    CancelToken? cancelToken,
  }) =>
      _send(
        () => _dio.get<Object?>(path, queryParameters: query, cancelToken: cancelToken),
        parse: parse,
        cacheKey: cacheKey == null ? null : _key(cacheKey, query),
      );

  Future<ApiResult<T>> post<T>(
    String path, {
    required JsonParser<T> parse,
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) =>
      _send(() => _dio.post<Object?>(path, data: body, queryParameters: query, options: Options(headers: headers)),
          parse: parse);

  Future<ApiResult<T>> put<T>(String path, {required JsonParser<T> parse, Object? body}) =>
      _send(() => _dio.put<Object?>(path, data: body), parse: parse);

  Future<ApiResult<T>> delete<T>(String path, {required JsonParser<T> parse, Object? body}) =>
      _send(() => _dio.delete<Object?>(path, data: body), parse: parse);

  /// Çoklu parça (belge / fotoğraf yükleme).
  Future<ApiResult<T>> upload<T>(String path, {required JsonParser<T> parse, required FormData form}) =>
      _send(() => _dio.post<Object?>(path, data: form), parse: parse);

  Future<ApiResult<T>> _send<T>(
    Future<Response<Object?>> Function() call, {
    required JsonParser<T> parse,
    String? cacheKey,
  }) async {
    try {
      final res = await call();
      final body = res.data;
      final envelope = body is Map<String, dynamic> ? body : <String, dynamic>{'success': true, 'data': body};
      if (envelope['success'] == false) {
        return Failure(ServerException(serverMessage: envelope['message'] as String?, statusCode: res.statusCode));
      }
      final data = envelope['data'];
      final meta = envelope['meta'];
      if (cacheKey != null) await _cache.writeString(cacheKey, jsonEncode(data));
      return Success(parse(data), meta: meta is Map<String, dynamic> ? PageMeta.fromJson(meta) : null);
    } on DioException catch (e) {
      final error = AppException.fromDio(e);
      if (error is NetworkException && cacheKey != null) {
        final cached = _readCache<T>(cacheKey, parse);
        if (cached != null) return Success(cached, fromCache: true);
      }
      return Failure(error);
    } on AppException catch (e) {
      return Failure(e);
    } on Object catch (e) {
      // Model/parse hataları: TypeError, FormatException, CheckedFromJsonException …
      return Failure(ParseException(e));
    }
  }

  T? _readCache<T>(String key, JsonParser<T> parse) {
    final raw = _cache.readString(key);
    if (raw == null) return null;
    try {
      return parse(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  String _key(String base, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return 'api.$base';
    final parts = query.entries.map((e) => '${e.key}=${e.value}').toList()..sort();
    return 'api.$base?${parts.join('&')}';
  }
}

/// Yardımcı çözücüler.
abstract final class Json {
  static Map<String, dynamic> map(Object? data) => (data as Map).cast<String, dynamic>();

  static List<T> list<T>(Object? data, T Function(Map<String, dynamic> j) f) {
    final source = data is Map ? (data['items'] ?? const []) : (data ?? const []);
    return (source as List).map((e) => f((e as Map).cast<String, dynamic>())).toList();
  }

  static void ignore(Object? _) {}
}

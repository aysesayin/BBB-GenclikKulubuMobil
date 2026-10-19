import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Yalnız debug derlemede; TCKN, şifre, token gibi alanları maskeler.
class LoggingInterceptor extends Interceptor {
  static const _sensitive = {'tckn', 'password', 'newPassword', 'accessToken', 'refreshToken', 'otp', 'pin', 'code'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) debugPrint('→ ${options.method} ${options.path} ${_mask(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) debugPrint('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) debugPrint('✕ ${err.response?.statusCode ?? err.type.name} ${err.requestOptions.path}');
    handler.next(err);
  }

  static Object? _mask(Object? data) {
    if (data is! Map) return data;
    return {for (final e in data.entries) e.key: _sensitive.contains(e.key) ? '***' : e.value};
  }
}

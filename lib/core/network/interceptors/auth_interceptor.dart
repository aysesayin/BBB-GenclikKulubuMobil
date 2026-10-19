import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../../storage/secure_storage.dart';

/// Bearer token, dil ve cihaz başlıklarını ekler.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secure);

  final SecureStorage _secure;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secure.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    options.headers['Accept-Language'] = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final device = await _secure.deviceId;
    if (device != null) options.headers['X-Device-Id'] = device;
    handler.next(options);
  }
}

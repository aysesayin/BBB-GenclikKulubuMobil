import 'package:dio/dio.dart';

import '../../session/session_controller.dart';
import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';

/// 401 alındığında refresh token ile yeni access token alır ve isteği
/// bir kez tekrarlar. Refresh başarısızsa oturum kapatılır (misafire düşer).
class RefreshInterceptor extends QueuedInterceptor {
  RefreshInterceptor({required Dio dio, required SecureStorage secure, required SessionController session})
      : _dio = dio,
        _secure = secure,
        _session = session;

  final Dio _dio;
  final SecureStorage _secure;
  final SessionController _session;

  static const _retried = 'x-retried';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final isAuthCall = req.path.startsWith('/auth/');
    if (err.response?.statusCode != 401 || isAuthCall || req.extra[_retried] == true) {
      return handler.next(err);
    }
    final refresh = await _secure.refreshToken;
    if (refresh == null) return handler.next(err);
    try {
      final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.refreshToken, data: {'refreshToken': refresh});
      final data = (res.data?['data'] as Map?)?.cast<String, dynamic>();
      final access = data?['accessToken'] as String?;
      final newRefresh = data?['refreshToken'] as String? ?? refresh;
      if (access == null) throw StateError('refresh yanıtı token içermiyor');
      await _secure.saveTokens(access: access, refresh: newRefresh);
      req.headers['Authorization'] = 'Bearer $access';
      req.extra[_retried] = true;
      handler.resolve(await _dio.fetch<Object?>(req));
    } on Object {
      await _session.signOut();
      handler.next(err);
    }
  }
}

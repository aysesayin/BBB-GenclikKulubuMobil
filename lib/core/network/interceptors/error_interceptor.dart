import 'package:dio/dio.dart';

import '../app_exception.dart';

/// HTTP 2xx olsa bile zarf `success:false` ise ve tüm hata yanıtlarında
/// hatayı tipli [AppException]'a çevirir (DioException.error içinde taşınır).
class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map && data['success'] == false) {
      final ex = DioException(requestOptions: response.requestOptions, response: response, type: DioExceptionType.badResponse);
      return handler.reject(ex.copyWith(error: AppException.fromDio(ex)));
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is AppException) return handler.next(err);
    handler.next(err.copyWith(error: AppException.fromDio(err)));
  }
}

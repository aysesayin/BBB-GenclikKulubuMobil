import 'package:dio/dio.dart';

/// Uygulama genelindeki hata tipleri. UI mesajı l10n'den seçilir ([kind]'a göre);
/// sunucu `message` gönderdiyse [serverMessage] öncelikli gösterilir.
sealed class AppException implements Exception {
  const AppException({this.serverMessage, this.fieldErrors = const {}});

  final String? serverMessage;

  /// `errors: [{field, message}]` alanlarından türetilir (form doğrulama).
  final Map<String, String> fieldErrors;

  static AppException fromDio(DioException e) {
    final err = e.error;
    if (err is AppException) return err;
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        const NetworkException(),
      DioExceptionType.cancel => const CancelledException(),
      _ => _fromResponse(e.response),
    };
  }

  static AppException _fromResponse(Response<dynamic>? r) {
    final data = r?.data;
    String? message;
    final fields = <String, String>{};
    if (data is Map) {
      message = data['message'] as String?;
      final errors = data['errors'];
      if (errors is List) {
        for (final item in errors.whereType<Map>()) {
          final f = item['field'], m = item['message'];
          if (f is String && m is String) fields[f] = m;
        }
      }
    }
    return switch (r?.statusCode) {
      401 => UnauthorizedException(serverMessage: message),
      403 => ForbiddenException(serverMessage: message),
      404 => NotFoundException(serverMessage: message),
      409 => ConflictException(serverMessage: message),
      422 || 400 => ValidationException(serverMessage: message, fieldErrors: fields),
      429 => RateLimitException(serverMessage: message),
      503 => MaintenanceException(serverMessage: message),
      _ => ServerException(serverMessage: message, statusCode: r?.statusCode),
    };
  }
}

/// İnternet yok / zaman aşımı → çevrimdışı durumu.
final class NetworkException extends AppException {
  const NetworkException();
}

final class CancelledException extends AppException {
  const CancelledException();
}

/// Oturum yok veya süresi doldu → misafir duvarı / giriş.
final class UnauthorizedException extends AppException {
  const UnauthorizedException({super.serverMessage});
}

/// Yaş sınırı, kota vb. iş kuralı reddi.
final class ForbiddenException extends AppException {
  const ForbiddenException({super.serverMessage});
}

final class NotFoundException extends AppException {
  const NotFoundException({super.serverMessage});
}

/// Stok bitti, kontenjan doldu, zaten alındı.
final class ConflictException extends AppException {
  const ConflictException({super.serverMessage});
}

final class ValidationException extends AppException {
  const ValidationException({super.serverMessage, super.fieldErrors});
}

final class RateLimitException extends AppException {
  const RateLimitException({super.serverMessage});
}

final class MaintenanceException extends AppException {
  const MaintenanceException({super.serverMessage});
}

final class ServerException extends AppException {
  const ServerException({super.serverMessage, this.statusCode});
  final int? statusCode;
}

/// Yanıt beklenen biçimde değil (parse hatası).
final class ParseException extends AppException {
  const ParseException([this.cause]);
  final Object? cause;
}

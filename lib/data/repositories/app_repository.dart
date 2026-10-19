import '../../core/network/api_result.dart';
import '../models/app/app_config.dart';
import '../services/app_service.dart';

/// Örnek repository kalıbı: soyut arayüz + uygulama. ViewModel'ler yalnız
/// soyut tipe bağımlıdır; testlerde mocktail ile taklit edilir.
abstract interface class AppRepository {
  /// Son başarılı yapılandırma (yoksa varsayılanlar).
  AppConfig get current;
  Future<ApiResult<AppConfig>> fetchConfig();
  Future<ApiResult<String>> legalText(String key);
}

class AppRepositoryImpl implements AppRepository {
  AppRepositoryImpl(this._service);

  final AppService _service;
  AppConfig _current = const AppConfig();

  @override
  AppConfig get current => _current;

  @override
  Future<ApiResult<AppConfig>> fetchConfig() async {
    final r = await _service.config();
    if (r case Success(:final data)) _current = data;
    return r;
  }

  @override
  Future<ApiResult<String>> legalText(String key) => _service.legalText(key);
}

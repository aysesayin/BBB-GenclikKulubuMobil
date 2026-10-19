import '../../core/network/api_result.dart';
import '../models/services/application.dart';
import '../services/application_service.dart';

/// Başvurularım (havuz, kurs, etkinlik başvuruları).
abstract interface class ApplicationRepository {
  Future<ApiResult<List<Application>>> list({String? status});
  Future<ApiResult<CancelResult>> cancel(String id);
}

class ApplicationRepositoryImpl implements ApplicationRepository {
  ApplicationRepositoryImpl(this._service);

  final ApplicationService _service;

  @override
  Future<ApiResult<List<Application>>> list({String? status}) => _service.list(status: status);

  @override
  Future<ApiResult<CancelResult>> cancel(String id) => _service.cancel(id);
}

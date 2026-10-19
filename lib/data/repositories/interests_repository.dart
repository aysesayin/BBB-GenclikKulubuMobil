import '../../core/network/api_result.dart';
import '../models/auth/interest_option.dart';
import '../services/interests_service.dart';

/// İlgi alanları. Kayıttan önce seçilen alanlar bellekte bekletilir ([held]),
/// kayıt başarılı olunca [saveHeld] ile `/users/me/interests`'e yazılır.
abstract interface class InterestsRepository {
  Future<ApiResult<List<InterestOption>>> options();
  Future<ApiResult<List<String>>> mine();
  Future<ApiResult<void>> save(Set<String> ids);

  Set<String> get held;
  void hold(Set<String> ids);
  Future<ApiResult<void>> saveHeld();
}

class InterestsRepositoryImpl implements InterestsRepository {
  InterestsRepositoryImpl(this._service);

  final InterestsService _service;
  Set<String> _held = const {};

  @override
  Future<ApiResult<List<InterestOption>>> options() => _service.options();

  @override
  Future<ApiResult<List<String>>> mine() => _service.mine();

  @override
  Future<ApiResult<void>> save(Set<String> ids) => _service.save(ids.toList());

  @override
  Set<String> get held => _held;

  @override
  void hold(Set<String> ids) => _held = Set.unmodifiable(ids);

  @override
  Future<ApiResult<void>> saveHeld() async {
    if (_held.isEmpty) return const Success(null);
    final r = await save(_held);
    if (r is Success) _held = const {};
    return r;
  }
}

import '../../core/network/api_result.dart';
import '../models/home/home_feed.dart';
import '../services/home_service.dart';

abstract interface class HomeRepository {
  /// Keşfet akışı. Ağ hatasında önbellek varsa `Success(fromCache: true)`.
  Future<ApiResult<HomeFeed>> fetchHome();
}

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._service);

  final HomeService _service;

  @override
  Future<ApiResult<HomeFeed>> fetchHome() => _service.home();
}

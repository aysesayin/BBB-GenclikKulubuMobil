import 'package:get_it/get_it.dart';

import '../../../data/repositories/buan_repository.dart';
import '../../../data/services/buan_service.dart';

/// buan özelliğinin service + repository kayıtları.
void registerBuanModule(GetIt sl) {
  sl
    ..registerLazySingleton<BuanService>(() => BuanService(sl()))
    ..registerLazySingleton<BuanRepository>(() => BuanRepositoryImpl(sl()));
}

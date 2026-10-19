import 'package:get_it/get_it.dart';

import '../../../data/repositories/buan_tasks_repository.dart';
import '../../../data/repositories/games_repository.dart';
import '../../../data/services/buan_tasks_service.dart';
import '../../../data/services/games_service.dart';

/// buan_tasks (E7–E12) + games (F) özelliklerinin service + repository kayıtları.
// TODO(varsayım): Oyunlar için ayrı modül dosyası yok (locator çekirdekte); entegratör isterse games_module.dart'a ayırabilir.
void registerBuanTasksModule(GetIt sl) {
  sl
    ..registerLazySingleton<BuanTasksService>(() => BuanTasksService(sl()))
    ..registerLazySingleton<DailySpinRepository>(() => DailySpinRepositoryImpl(sl()))
    ..registerLazySingleton<WatchEarnRepository>(() => WatchEarnRepositoryImpl(sl()))
    ..registerLazySingleton<StepsRepository>(() => StepsRepositoryImpl(sl()))
    ..registerLazySingleton<QuizRepository>(() => QuizRepositoryImpl(sl()))
    ..registerLazySingleton<ReferralRepository>(() => ReferralRepositoryImpl(sl()))
    ..registerLazySingleton<PhotoReportRepository>(() => PhotoReportRepositoryImpl(sl()))
    ..registerLazySingleton<GamesService>(() => GamesService(sl()))
    ..registerLazySingleton<GamesRepository>(() => GamesRepositoryImpl(sl()));
}

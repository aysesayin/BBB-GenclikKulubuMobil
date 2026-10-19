import 'package:get_it/get_it.dart';

import '../../../data/repositories/home_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/search_repository.dart';
import '../../../data/repositories/story_repository.dart';
import '../../../data/services/home_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/search_service.dart';
import '../../../data/services/story_service.dart';

/// Keşfet (B) özelliğinin service + repository kayıtları: home, arama, bildirim, hikâye.
void registerHomeModule(GetIt sl) {
  sl
    ..registerLazySingleton<HomeService>(() => HomeService(sl()))
    ..registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()))
    ..registerLazySingleton<SearchService>(() => SearchService(sl()))
    ..registerLazySingleton<SearchRepository>(() => SearchRepositoryImpl(sl(), sl()))
    ..registerLazySingleton<NotificationService>(() => NotificationService(sl()))
    ..registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(sl()))
    ..registerLazySingleton<StoryService>(() => StoryService(sl()))
    ..registerLazySingleton<StoryRepository>(() => StoryRepositoryImpl(sl()));
}

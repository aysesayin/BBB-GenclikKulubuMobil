import 'package:get_it/get_it.dart';

import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/map_repository.dart';
import '../../../data/repositories/place_repository.dart';
import '../../../data/services/event_service.dart';
import '../../../data/services/map_service.dart';
import '../../../data/services/place_service.dart';

/// G · Etkinlikler ve Keşif: etkinlik, harita ve yer/tesis service + repository kayıtları.
void registerEventsModule(GetIt sl) {
  sl
    ..registerLazySingleton<EventService>(() => EventService(sl()))
    ..registerLazySingleton<EventRepository>(() => EventRepositoryImpl(sl()))
    ..registerLazySingleton<MapService>(() => MapService(sl()))
    ..registerLazySingleton<MapRepository>(() => MapRepositoryImpl(sl()))
    ..registerLazySingleton<PlaceService>(() => PlaceService(sl()))
    ..registerLazySingleton<PlaceRepository>(() => PlaceRepositoryImpl(sl()));
}

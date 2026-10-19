import 'package:get_it/get_it.dart';

import '../../../data/repositories/card_repository.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../../data/services/card_service.dart';
import '../../../data/services/opportunity_service.dart';

/// Fırsatlar (C) + Kartım/QR (D) özelliklerinin service + repository kayıtları.
// Not: Kartım için ayrı modül dosyası yok; entegratör isterse `card_module.dart`'a taşıyabilir.
void registerOpportunitiesModule(GetIt sl) {
  sl
    ..registerLazySingleton<OpportunityService>(() => OpportunityService(sl()))
    ..registerLazySingleton<OpportunityRepository>(() => OpportunityRepositoryImpl(sl()))
    ..registerLazySingleton<CardService>(() => CardService(sl()))
    ..registerLazySingleton<CardRepository>(() => CardRepositoryImpl(sl(), sl()));
}

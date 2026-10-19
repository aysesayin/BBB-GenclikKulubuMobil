import 'package:get_it/get_it.dart';

import '../../../data/repositories/application_repository.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/services/application_service.dart';
import '../../../data/services/cart_payment_launcher.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/facility_service.dart';

/// services özelliğinin service + repository kayıtları.
void registerServicesModule(GetIt sl) {
  sl
    ..registerLazySingleton<FacilityService>(() => FacilityService(sl()))
    ..registerLazySingleton<FacilityRepository>(() => FacilityRepositoryImpl(sl()))
    ..registerLazySingleton<CartService>(() => CartService(sl()))
    ..registerLazySingleton<CartRepository>(() => CartRepositoryImpl(sl()))
    ..registerLazySingleton<PaymentLauncher>(() => const UrlPaymentLauncher())
    ..registerLazySingleton<ApplicationService>(() => ApplicationService(sl()))
    ..registerLazySingleton<ApplicationRepository>(() => ApplicationRepositoryImpl(sl()));
}

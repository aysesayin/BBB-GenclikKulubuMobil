import 'package:get_it/get_it.dart';

import '../../../data/repositories/coupon_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/support_repository.dart';
import '../../../data/services/coupon_service.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/support_service.dart';

/// profile özelliğinin service + repository kayıtları.
void registerProfileModule(GetIt sl) {
  sl
    ..registerLazySingleton<ProfileService>(() => ProfileService(sl()))
    ..registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()))
    ..registerLazySingleton<CouponService>(() => CouponService(sl()))
    ..registerLazySingleton<CouponRepository>(() => CouponRepositoryImpl(sl()))
    ..registerLazySingleton<SupportService>(() => SupportService(sl()))
    ..registerLazySingleton<SupportRepository>(() => SupportRepositoryImpl(sl()));
}

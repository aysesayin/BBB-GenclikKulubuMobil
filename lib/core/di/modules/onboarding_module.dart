import 'package:get_it/get_it.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/interests_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/interests_service.dart';
import '../../../features/auth/biometric_authenticator.dart';
import '../../../features/onboarding/permission_gateway.dart';

/// Giriş akışı (onboarding + auth) service + repository kayıtları.
void registerOnboardingModule(GetIt sl) {
  sl
    ..registerLazySingleton<AuthService>(() => AuthService(sl()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()))
    ..registerLazySingleton<InterestsService>(() => InterestsService(sl()))
    ..registerLazySingleton<InterestsRepository>(() => InterestsRepositoryImpl(sl()))
    ..registerLazySingleton<BiometricAuthenticator>(LocalBiometricAuthenticator.new)
    ..registerLazySingleton<PermissionGateway>(DevicePermissionGateway.new);
}

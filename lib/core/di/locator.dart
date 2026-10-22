import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../data/repositories/app_repository.dart';
import '../../data/services/app_service.dart';
import '../network/dio_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/error_interceptor.dart';
import '../network/interceptors/logging_interceptor.dart';
import '../network/interceptors/mock_interceptor.dart';
import '../network/interceptors/refresh_interceptor.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import '../session/session_controller.dart';
import '../storage/cache_store.dart';
import '../storage/secure_storage.dart';
import '../theme/theme_controller.dart';
import '../theme/ui_prefs_controller.dart';
import 'modules/buan_module.dart';
import 'modules/buan_tasks_module.dart';
import 'modules/events_module.dart';
import 'modules/home_module.dart';
import 'modules/onboarding_module.dart';
import 'modules/opportunities_module.dart';
import 'modules/profile_module.dart';
import 'modules/services_module.dart';

/// Servis bulucu. ViewModel'ler kayıtlı DEĞİLDİR; görünüm kendi ViewModel'ini
/// `ChangeNotifierProvider(create: (_) => XViewModel(sl<XRepository>()))` ile kurar.
final sl = GetIt.instance;

Future<void> setupLocator() async {
  final cache = await CacheStore.create();
  sl
    ..registerSingleton<CacheStore>(cache)
    ..registerSingleton<SecureStorage>(SecureStorage())
    ..registerSingleton<ThemeController>(ThemeController(cache))
    ..registerSingleton<UiPrefsController>(UiPrefsController(cache))
    ..registerSingleton<AnalyticsService>(DebugAnalyticsService())
    ..registerSingleton<ConnectivityService>(ConnectivityService());
  sl.registerSingleton<SessionController>(SessionController(secure: sl(), cache: cache));

  final dio = Dio(DioClient.baseOptions());
  dio.interceptors.addAll([
    AuthInterceptor(sl()),
    if (kDebugMode) LoggingInterceptor(),
    MockInterceptor(),
    ErrorInterceptor(),
    RefreshInterceptor(dio: dio, secure: sl(), session: sl()),
  ]);
  sl
    ..registerSingleton<Dio>(dio)
    ..registerSingleton<DioClient>(DioClient(dio: dio, cache: cache))
    ..registerLazySingleton<AppService>(() => AppService(sl()))
    ..registerLazySingleton<AppRepository>(() => AppRepositoryImpl(sl()));

  // Özellik modülleri (her biri kendi service + repository kayıtlarını yapar).
  registerOnboardingModule(sl);
  registerHomeModule(sl);
  registerOpportunitiesModule(sl);
  registerBuanModule(sl);
  registerBuanTasksModule(sl);
  registerEventsModule(sl);
  registerServicesModule(sl);
  registerProfileModule(sl);
}

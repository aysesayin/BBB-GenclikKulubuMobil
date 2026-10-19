import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/di/locator.dart';
import 'core/network/api_endpoints.dart';
import 'core/services/connectivity_service.dart';
import 'core/session/session_controller.dart';

/// Flavor'lar: `--dart-define=ENV=dev|staging|prod` ve `--dart-define=MOCK=true|false`.
/// Backend hazır olana kadar varsayılan MOCK=true (assets/mock/*.json).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  ApiConfig.env = AppEnv.values.firstWhere((e) => e.name == env, orElse: () => AppEnv.dev);
  ApiConfig.useMock = const bool.fromEnvironment('MOCK', defaultValue: true);

  await Future.wait([
    initializeDateFormatting('tr'),
    initializeDateFormatting('en'),
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]);
  await setupLocator();
  await sl<ConnectivityService>().start();
  // Deep link ile splash atlansa da oturum hazır olsun (splash ayrıca yapılandırmayı yükler).
  await sl<SessionController>().restore();

  runApp(const GenclikApp());
}

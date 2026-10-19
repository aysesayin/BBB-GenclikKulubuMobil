import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/data/models/app/app_config.dart';
import 'package:bbb_genclik_kulubu_app/features/splash/view_model/splash_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fakes.dart';

void main() {
  setUpAll(registerAuthFallbacks);

  group('SplashViewModel', () {
    Future<SplashViewModel> run({
      bool seen = false,
      bool auth = false,
      AppConfig config = const AppConfig(),
      bool failMaintenance = false,
    }) async {
      final session = stubSession(authenticated: auth, onboardingSeen: seen);
      final app = stubApp(config);
      when(
        app.fetchConfig,
      ).thenAnswer((_) async => failMaintenance ? const Failure(MaintenanceException(serverMessage: 'bakım')) : Success(config));
      final vm = SplashViewModel(session, app);
      await vm.start();
      verify(session.restore).called(1);
      return vm;
    }

    test('onboarding görülmediyse hikâyeye gider', () async {
      final vm = await run();
      expect(vm.phase, SplashPhase.ready);
      expect(vm.destination, Routes.onboarding);
    });

    test('üye ise Keşfet', () async {
      final vm = await run(seen: true, auth: true);
      expect(vm.destination, Routes.home);
    });

    test('misafir ve onboarding görüldü → karşılama', () async {
      final vm = await run(seen: true);
      expect(vm.destination, Routes.welcome);
    });

    test('yapılandırmada bakım modu → bakım ekranı', () async {
      final vm = await run(config: const AppConfig(maintenance: true, maintenanceMessage: 'Az sonra'));
      expect(vm.phase, SplashPhase.maintenance);
      expect(vm.maintenanceMessage, 'Az sonra');
      expect(vm.destination, isNull);
    });

    test('503 MaintenanceException → bakım ekranı', () async {
      final vm = await run(failMaintenance: true);
      expect(vm.phase, SplashPhase.maintenance);
      expect(vm.maintenanceMessage, 'bakım');
    });

    test('ağ hatasında varsayılanlarla devam eder', () async {
      final session = stubSession();
      final app = stubApp();
      when(app.fetchConfig).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = SplashViewModel(session, app);
      await vm.start();
      expect(vm.phase, SplashPhase.ready);
      expect(vm.destination, Routes.onboarding);
    });
  });
}

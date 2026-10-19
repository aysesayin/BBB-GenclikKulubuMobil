import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/data/models/app/app_config.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/interest_option.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/permission_gateway.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/view_model/interests_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/view_model/permissions_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/view_model/story_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/view_model/summit_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/view_model/welcome_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fakes.dart';

void main() {
  setUpAll(registerAuthFallbacks);

  group('StoryViewModel', () {
    late MockAuthRepository auth;
    setUp(() {
      auth = MockAuthRepository();
      when(() => auth.onboardingBonusHeld).thenReturn(false);
      when(auth.holdOnboardingBonus).thenAnswer((_) async {});
    });

    test('ileri / geri sınırlar içinde kalır, son hikâyede bekler', () {
      final vm = StoryViewModel(auth, stubApp());
      vm.prev();
      expect(vm.index, 0);
      vm.onSegmentDone();
      vm.next();
      expect(vm.index, 2);
      expect(vm.isLast, isTrue);
      vm.onSegmentDone();
      expect(vm.index, 2);
    });

    test('coin dokunuşu bonusu bekletir ve devamı açar', () async {
      final vm = StoryViewModel(auth, stubApp(const AppConfig(onboardingBonus: 150)));
      expect(vm.canFinish, isFalse);
      expect(vm.bonus, 150);
      await vm.popCoin();
      await vm.popCoin();
      expect(vm.coinPopped, isTrue);
      expect(vm.canFinish, isTrue);
      verify(auth.holdOnboardingBonus).called(1);
    });

    test('duraklatma ve kupon fırlatma; hikâye değişince kupon sıfırlanır', () {
      final vm = StoryViewModel(auth, stubApp())..setPaused(value: true);
      expect(vm.paused, isTrue);
      vm
        ..goTo(1)
        ..flingCoupon(3);
      expect(vm.paused, isFalse);
      expect(vm.flungCoupon, 3);
      vm.next();
      expect(vm.flungCoupon, isNull);
    });
  });

  group('WelcomeViewModel', () {
    test('misafir olarak gez → onboarding kapanır, Keşfet', () async {
      final session = stubSession();
      final vm = WelcomeViewModel(session, stubApp());
      expect(await vm.continueAsGuest(), Routes.home);
      verify(session.continueAsGuest).called(1);
      verify(session.markOnboardingSeen).called(1);
      expect(vm.bonus, 100);
    });

    test('from girişe taşınır', () {
      expect(WelcomeViewModel(stubSession(), stubApp()).loginRoute, Routes.login);
      final vm = WelcomeViewModel(stubSession(), stubApp(), from: '/kartim');
      expect(Uri.parse(vm.loginRoute).queryParameters['from'], '/kartim');
    });
  });

  group('InterestsViewModel', () {
    late MockInterestsRepository repo;
    const options = [InterestOption(id: 'a', label: 'A'), InterestOption(id: 'b', label: 'B'), InterestOption(id: 'c', label: 'C')];
    setUp(() {
      repo = MockInterestsRepository();
      when(() => repo.held).thenReturn(const {});
      when(repo.options).thenAnswer((_) async => const Success(options));
      when(() => repo.hold(any())).thenReturn(null);
    });

    test('yükler; 3 seçim olmadan devam edilemez', () async {
      final vm = InterestsViewModel(repo);
      await vm.load();
      expect(vm.state, isA<ViewSuccess<List<InterestOption>>>());
      vm
        ..toggle('a')
        ..toggle('b');
      expect(vm.canContinue, isFalse);
      expect(vm.submit(), isFalse);
      vm.toggle('c');
      expect(vm.lastSelected, 'c');
      expect(vm.canContinue, isTrue);
      expect(vm.submit(), isTrue);
      verify(() => repo.hold({'a', 'b', 'c'})).called(1);
    });

    test('tekrar dokunmak seçimi kaldırır', () {
      final vm = InterestsViewModel(repo)
        ..toggle('a')
        ..toggle('a');
      expect(vm.count, 0);
      expect(vm.lastSelected, isNull);
    });

    test('bekletilen seçim geri yüklenir; hata durumu', () async {
      when(() => repo.held).thenReturn(const {'a', 'b'});
      when(repo.options).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = InterestsViewModel(repo);
      expect(vm.count, 2);
      await vm.load();
      expect(vm.state, isA<ViewError<List<InterestOption>>>());
    });
  });

  group('SummitViewModel', () {
    test('kayıt yanıtından kart ve 100 + 500 = 600', () {
      final auth = MockAuthRepository();
      when(() => auth.lastRegistration).thenReturn(demoSession);
      when(() => auth.onboardingBonusHeld).thenReturn(false);
      final vm = SummitViewModel(auth, stubApp(), stubSession());
      expect(vm.fullName, 'Ayşe Su');
      expect(vm.memberNo, '0016 4821');
      expect(vm.total, 600);
      expect(vm.inviteReward, 2000);
      expect(vm.qrData, 'qr');
    });

    test('kayıt yanıtı yoksa panel varsayılanları; coin dokunulmadıysa onboarding 0', () {
      final auth = MockAuthRepository();
      when(() => auth.lastRegistration).thenReturn(null);
      when(() => auth.onboardingBonusHeld).thenReturn(false);
      final vm = SummitViewModel(auth, stubApp(), stubSession());
      expect(vm.onboardingBonus, 0);
      expect(vm.total, 500);
      expect(vm.qrData, 'usr-demo');
    });
  });

  group('PermissionsViewModel', () {
    test('kartlar sırayla geçilir, izin sayılır, bitince Keşfet', () async {
      final gw = MockPermissionGateway();
      when(() => gw.request(any())).thenAnswer((i) async => i.positionalArguments.first == OnbPermission.location);
      final session = stubSession();
      final vm = PermissionsViewModel(gw, session);
      expect(vm.current, 0);
      await vm.allow();
      expect(vm.flungRight(OnbPermission.location), isTrue);
      expect(vm.current, 1);
      vm.skip();
      expect(vm.flungRight(OnbPermission.notifications), isFalse);
      await vm.allow(); // motion: gateway false döner
      expect(vm.done, isTrue);
      expect(vm.granted, 1);
      verifyNever(() => gw.request(OnbPermission.notifications));
      expect(await vm.finish(), Routes.home);
      verify(session.markOnboardingSeen).called(1);
    });
  });
}

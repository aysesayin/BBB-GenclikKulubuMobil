import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/core/utils/validators.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/auth_requests.dart';
import 'package:bbb_genclik_kulubu_app/features/auth/view_model/login_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../onboarding/fakes.dart';

void main() {
  setUpAll(registerAuthFallbacks);

  late MockAuthRepository auth;
  late MockSession session;
  late MockBiometric bio;

  LoginViewModel make({String? from}) => LoginViewModel(auth, session, bio, from: from);

  setUp(() {
    auth = MockAuthRepository();
    session = stubSession();
    bio = MockBiometric();
    when(bio.isAvailable).thenAnswer((_) async => true);
    when(() => bio.authenticate(any())).thenAnswer((_) async => true);
    when(() => auth.login(any())).thenAnswer((_) async => const Success(demoSession));
    when(auth.biometricLogin).thenAnswer((_) async => const Success(demoSession));
  });

  test('geçersiz TCKN → kimlik hatası, istek atılmaz', () async {
    final vm = make()
      ..setIdentifier('12345678901')
      ..setPassword('x');
    expect(await vm.submit(), isFalse);
    expect(vm.error, LoginError.identifier);
    expect(vm.identifierIssue, ValidationIssue.tcknInvalid);
    verifyNever(() => auth.login(any()));
  });

  test('boş şifre → hata + sallanma', () async {
    final vm = make()..setIdentifier('10000000146');
    expect(await vm.submit(), isFalse);
    expect(vm.error, LoginError.passwordRequired);
    expect(vm.shakeTick, 1);
  });

  test('başarılı giriş → oturum açılır, from veya Keşfet', () async {
    final vm = make(from: '/kartim')
      ..setIdentifier('10000000146')
      ..setPassword('Sifre123');
    expect(await vm.submit(), isTrue);
    expect(vm.destination, '/kartim');
    final req = verify(() => auth.login(captureAny())).captured.single as LoginRequest;
    expect(req.method, LoginMethod.tckn);
    expect(req.identifier, '10000000146');
    verify(
      () => session.signIn(
        accessToken: 'a',
        refreshToken: 'r',
        user: any(named: 'user'),
      ),
    ).called(1);
    verify(session.markOnboardingSeen).called(1);
    expect(make().destination, isNull);
  });

  test('hatalı şifre → kalan hak azalır, 3. denemede kilit', () async {
    when(() => auth.login(any())).thenAnswer((_) async => const Failure(UnauthorizedException()));
    final vm = make()
      ..setIdentifier('10000000146')
      ..setPassword('yanlis123');
    await vm.submit();
    expect(vm.error, LoginError.wrongPassword);
    expect(vm.remainingAttempts, 2);
    await vm.submit();
    expect(vm.remainingAttempts, 1);
    await vm.submit();
    expect(vm.error, LoginError.locked);
    expect(await vm.submit(), isFalse);
    verify(() => auth.login(any())).called(3);
  });

  test('yöntem değişince kimlik sıfırlanır; e-posta doğrulaması', () async {
    final vm = make()
      ..setIdentifier('10000000146')
      ..setMethod(LoginMethod.email);
    expect(vm.identifier, '');
    vm
      ..setIdentifier('ayse@')
      ..setPassword('x');
    await vm.submit();
    expect(vm.identifierIssue, ValidationIssue.emailInvalid);
  });

  test('Face ID: uygun değilse hata, uygunsa giriş', () async {
    when(bio.isAvailable).thenAnswer((_) async => false);
    var vm = make();
    await vm.init();
    expect(await vm.biometricLogin('neden'), isFalse);
    expect(vm.error, LoginError.biometricUnavailable);

    when(bio.isAvailable).thenAnswer((_) async => true);
    vm = make();
    await vm.init();
    expect(await vm.biometricLogin('neden'), isTrue);
    expect(vm.destination, Routes.home);
  });

  test('şifremi unuttum', () async {
    when(() => auth.forgotPassword(any(), any())).thenAnswer((_) async => const Success(null));
    final vm = make()..setIdentifier('10000000146');
    expect(await vm.forgotPassword(), isTrue);
    expect(vm.forgotSent, isTrue);
    verify(() => auth.forgotPassword(LoginMethod.tckn, '10000000146')).called(1);
  });

  test('sunucu hatası → genel hata', () async {
    when(() => auth.login(any())).thenAnswer((_) async => const Failure(NetworkException()));
    final vm = make()
      ..setIdentifier('10000000146')
      ..setPassword('x1234567');
    await vm.submit();
    expect(vm.error, LoginError.other);
    expect(vm.failure, isA<NetworkException>());
  });
}

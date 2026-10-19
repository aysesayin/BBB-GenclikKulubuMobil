import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/auth_requests.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/otp_challenge.dart';
import 'package:bbb_genclik_kulubu_app/features/auth/view_model/register_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../onboarding/fakes.dart';

void main() {
  setUpAll(registerAuthFallbacks);

  late MockAuthRepository auth;
  late MockInterestsRepository interests;
  late MockSession session;
  final today = DateTime(2026, 10, 16);

  RegisterViewModel make({String? ref}) => RegisterViewModel(
    auth,
    interests,
    stubApp(),
    session,
    referralCode: ref,
    clock: () => today,
    minScene: Duration.zero,
    otpAdvance: Duration.zero,
  );

  setUp(() {
    auth = MockAuthRepository();
    interests = MockInterestsRepository();
    session = stubSession();
    when(() => auth.onboardingBonusHeld).thenReturn(true);
    when(
      () => auth.sendOtp(any(), resend: any(named: 'resend')),
    ).thenAnswer((_) async => const Success(OtpChallenge(maskedPhone: '0532 *** ** 90', resendIn: 3)));
    when(() => auth.verifyOtp(any(), any())).thenAnswer(
      (i) async => i.positionalArguments[1] == '481926'
          ? const Success(OtpVerification(verificationToken: 'otp-tok'))
          : const Failure(ValidationException()),
    );
    when(
      () => auth.verifyMernis(
        tckn: any(named: 'tckn'),
        birthDate: any(named: 'birthDate'),
      ),
    ).thenAnswer((_) async => const Success(MernisResult(verified: true)));
    when(() => auth.register(any())).thenAnswer((_) async => const Success(demoSession));
    when(
      () => auth.requestParentConsent(
        tckn: any(named: 'tckn'),
        birthDate: any(named: 'birthDate'),
        parentPhone: any(named: 'parentPhone'),
      ),
    ).thenAnswer((_) async => const Success(null));
    when(interests.saveHeld).thenAnswer((_) async => const Success(null));
  });

  Future<RegisterViewModel> toAgreements({String? ref}) async {
    final vm = make(ref: ref)..setTckn('10000000146');
    await vm.next();
    vm
      ..setPhone('532 418 27 90')
      ..setEmail('ayse@ornek.com');
    await vm.next();
    vm.setOtp('481926');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    vm
      ..setEmergencyName('Fatma Yılmaz')
      ..setEmergencyPhone('0533 201 44 18');
    await vm.next();
    return vm;
  }

  test('geçersiz TCKN → sallanma, adım değişmez', () async {
    final vm = make()..setTckn('12345678901');
    expect(vm.tcknStatus, TcknStatus.invalid);
    final shakes = vm.shakeTick;
    await vm.next();
    expect(vm.step, RegisterStep.identity);
    expect(vm.shakeTick, greaterThan(shakes));
    vm.dispose();
  });

  test('17 yaş → veli onayı; 15 yaş → misafir', () async {
    var vm = make()
      ..setTckn('10000000146')
      ..setBirthDate(DateTime(2009, 3, 1));
    await vm.next();
    expect(vm.step, RegisterStep.underAge);
    expect(vm.underAge, UnderAgeKind.needsParent);
    vm.setParentPhone('0532 000 00 00');
    await vm.next();
    expect(vm.parentSent, isTrue);
    expect(vm.back(), isTrue);
    expect(vm.step, RegisterStep.identity);

    vm = make()
      ..setTckn('10000000146')
      ..setBirthDate(DateTime(2011, 3, 1));
    await vm.next();
    expect(vm.underAge, UnderAgeKind.tooYoung);
    expect(vm.canContinue, isFalse);
  });

  test('yanlış OTP → hata + sallanma; doğru OTP → acil durum', () async {
    final vm = make()..setTckn('10000000146');
    await vm.next();
    vm.setPhone('123');
    await vm.next();
    expect(vm.step, RegisterStep.contact);
    verifyNever(() => auth.sendOtp(any(), resend: any(named: 'resend')));
    vm
      ..setPhone('5324182790')
      ..setEmail('ayse@ornek.com');
    await vm.next();
    expect(vm.step, RegisterStep.otp);
    expect(vm.maskedPhone, '0532 *** ** 90');
    expect(vm.resendLeft, 3);
    verify(() => auth.sendOtp('05324182790', resend: false)).called(1);

    vm.setOtp('000000');
    await Future<void>.delayed(Duration.zero);
    expect(vm.otpState, OtpState.wrong);
    vm.setOtp('481926');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(vm.step, RegisterStep.emergency);
    vm.dispose();
  });

  test('sözleşmeler: 4 zorunlu; Açık Rıza ayrı → MERNİS + kayıt + oturum + ilgi alanları', () async {
    final vm = await toAgreements(ref: 'DAVET1');
    expect(vm.step, RegisterStep.agreements);
    expect(vm.canContinue, isFalse);
    for (final d in LegalDoc.required.take(3)) {
      vm.toggleConsent(d);
    }
    expect(vm.canContinue, isFalse);
    vm.acceptConsent(LegalDoc.health);
    expect(vm.canContinue, isTrue);
    expect(vm.explicitConsent, isFalse);
    await vm.next();
    expect(vm.step, RegisterStep.verification);
    expect(vm.verifyStatus, VerifyStatus.verified);

    final req = verify(() => auth.register(captureAny())).captured.single as RegisterRequest;
    expect(req.tckn, '10000000146');
    expect(req.birthDate, '2004-03-14');
    expect(req.phone, '05324182790');
    expect(req.emergencyContact.phone, '05332014418');
    expect(req.otpToken, 'otp-tok');
    expect(req.acceptedConsents, ['terms', 'privacy', 'kvkk', 'health']);
    expect(req.explicitConsent, isFalse);
    expect(req.referralCode, 'DAVET1');
    expect(req.onboardingBonusClaimed, isTrue);
    verify(
      () => session.signIn(
        accessToken: 'a',
        refreshToken: 'r',
        user: any(named: 'user'),
      ),
    ).called(1);
    verify(interests.saveHeld).called(1);
    vm.dispose();
  });

  test('MERNİS eşleşmezse hata; geri → sözleşmeler', () async {
    when(
      () => auth.verifyMernis(
        tckn: any(named: 'tckn'),
        birthDate: any(named: 'birthDate'),
      ),
    ).thenAnswer((_) async => const Success(MernisResult(verified: false, message: 'eşleşmedi')));
    final vm = await toAgreements();
    for (final d in LegalDoc.required) {
      vm.toggleConsent(d);
    }
    await vm.next();
    expect(vm.verifyStatus, VerifyStatus.failed);
    expect(vm.error?.serverMessage, 'eşleşmedi');
    verifyNever(() => auth.register(any()));
    expect(vm.back(), isTrue);
    expect(vm.step, RegisterStep.agreements);
    vm.dispose();
  });

  test('misafir olarak devam', () async {
    final vm = make();
    await vm.continueAsGuest();
    verify(session.continueAsGuest).called(1);
    verify(session.markOnboardingSeen).called(1);
    expect(vm.back(), isFalse);
  });
}

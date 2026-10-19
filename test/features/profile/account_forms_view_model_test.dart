import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/utils/validators.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/account_settings.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/settings/view_model/contact_change_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/settings/view_model/password_change_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

void main() {
  late MockProfileRepository repo;

  setUpAll(registerProfileFallbacks);
  setUp(() => repo = MockProfileRepository());

  group('ContactChangeViewModel', () {
    const challenge = ContactChallenge(challengeId: 'chl-1', codeLength: 6);

    test('geçersiz telefon istek atmaz', () async {
      final vm = ContactChangeViewModel(repo, ContactKind.phone);
      expect(await vm.sendCode('0212 000 00 00'), isFalse);
      expect(vm.issue, ValidationIssue.phoneInvalid);
      verifyNever(() => repo.updateContact(any(), any()));
    });

    test('telefon normalize edilir, OTP adımına geçilir ve doğrulanır', () async {
      when(() => repo.updateContact(any(), any())).thenAnswer((_) async => const Success(challenge));
      when(() => repo.verifyContact(any(), any())).thenAnswer((_) async => const Success(null));
      final vm = ContactChangeViewModel(repo, ContactKind.phone);
      expect(await vm.sendCode('532 111 22 33'), isTrue);
      verify(() => repo.updateContact(ContactKind.phone, '05321112233')).called(1);
      expect(vm.step, ContactStep.verify);

      expect(await vm.verify('123'), isFalse);
      expect(vm.issue, ValidationIssue.otpLength);
      expect(await vm.verify('123456'), isTrue);
      verify(() => repo.verifyContact('chl-1', '123456')).called(1);
    });

    test('e-posta küçük harfe çevrilir; sunucu hatası saklanır', () async {
      when(() => repo.updateContact(any(), any())).thenAnswer((_) async => const Failure(ConflictException()));
      final vm = ContactChangeViewModel(repo, ContactKind.email);
      expect(await vm.sendCode(' Ayse@Ornek.com '), isFalse);
      verify(() => repo.updateContact(ContactKind.email, 'ayse@ornek.com')).called(1);
      expect(vm.error, isA<ConflictException>());
      expect(vm.step, ContactStep.enter);
    });

    test('yanlış kod hatası, düzelt ile ilk adıma dönülür', () async {
      when(() => repo.updateContact(any(), any())).thenAnswer((_) async => const Success(challenge));
      when(() => repo.verifyContact(any(), any())).thenAnswer((_) async => const Failure(ValidationException()));
      final vm = ContactChangeViewModel(repo, ContactKind.phone);
      await vm.sendCode('05321112233');
      expect(await vm.verify('000000'), isFalse);
      expect(vm.error, isA<ValidationException>());
      vm.editTarget();
      expect(vm.step, ContactStep.enter);
      expect(vm.error, isNull);
    });
  });

  group('PasswordChangeViewModel', () {
    test('zayıf / eşleşmeyen şifre istek atmaz', () async {
      final vm = PasswordChangeViewModel(repo);
      expect(await vm.submit(current: '', next: 'abc', repeat: 'abc'), isFalse);
      expect(vm.currentIssue, ValidationIssue.required);
      expect(vm.nextIssue, ValidationIssue.passwordWeak);
      expect(await vm.submit(current: 'eski1234', next: 'yeniSifre1', repeat: 'yeniSifre2'), isFalse);
      expect(vm.mismatch, isTrue);
      verifyNever(
        () => repo.changePassword(
          current: any(named: 'current'),
          next: any(named: 'next'),
        ),
      );
    });

    test('geçerli form gönderilir', () async {
      when(
        () => repo.changePassword(
          current: any(named: 'current'),
          next: any(named: 'next'),
        ),
      ).thenAnswer((_) async => const Success(null));
      final vm = PasswordChangeViewModel(repo);
      expect(await vm.submit(current: 'eski1234', next: 'yeniSifre1', repeat: 'yeniSifre1'), isTrue);
      verify(() => repo.changePassword(current: 'eski1234', next: 'yeniSifre1')).called(1);
    });

    test('sunucu hatası saklanır', () async {
      when(
        () => repo.changePassword(
          current: any(named: 'current'),
          next: any(named: 'next'),
        ),
      ).thenAnswer((_) async => const Failure(ValidationException(serverMessage: 'Mevcut şifre hatalı')));
      final vm = PasswordChangeViewModel(repo);
      expect(await vm.submit(current: 'eski1234', next: 'yeniSifre1', repeat: 'yeniSifre1'), isFalse);
      expect(vm.error?.serverMessage, 'Mevcut şifre hatalı');
      expect(vm.busy, isFalse);
    });
  });
}

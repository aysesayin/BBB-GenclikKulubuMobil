import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/account_settings.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/delete_request.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/settings/view_model/biometric_login.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/settings/view_model/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

void main() {
  late MockProfileRepository repo;
  late MockBiometricLogin bio;
  late SettingsViewModel vm;

  setUpAll(registerProfileFallbacks);

  setUp(() {
    repo = MockProfileRepository();
    bio = MockBiometricLogin();
    when(() => bio.availableKind()).thenAnswer((_) async => BiometricKind.face);
    when(() => bio.enabled).thenReturn(false);
    when(() => repo.me()).thenAnswer((_) async => const Success(demoUser));
    when(() => repo.preferences()).thenAnswer((_) async => const Success(NotificationPrefs()));
    vm = SettingsViewModel(repo, bio);
  });

  NotificationPrefs prefs() => (vm.state as ViewSuccess<SettingsData>).data.prefs;

  test('kullanıcı ve tercihler yüklenir, biyometri türü okunur', () async {
    await vm.load();
    await vm.biometricReady;
    expect(vm.state, isA<ViewSuccess<SettingsData>>());
    expect(vm.biometricKind, BiometricKind.face);
    expect(vm.biometricEnabled, isFalse);
  });

  test('tercihler alınamazsa hata durumu', () async {
    when(() => repo.preferences()).thenAnswer((_) async => const Failure(NetworkException()));
    await vm.load();
    expect(vm.state, isA<ViewError<SettingsData>>());
  });

  test('tercih iyimser güncellenir', () async {
    when(() => repo.updatePreferences(any())).thenAnswer((_) async => const Success(null));
    await vm.load();
    final error = await vm.updatePrefs((p) => p.copyWith(announcements: true));
    expect(error, isNull);
    expect(prefs().announcements, isTrue);
    verify(() => repo.updatePreferences(const NotificationPrefs(announcements: true))).called(1);
  });

  test('tercih kaydı başarısızsa geri alınır ve hata döner', () async {
    when(() => repo.updatePreferences(any())).thenAnswer((_) async => const Failure(ServerException()));
    await vm.load();
    final error = await vm.updatePrefs((p) => p.copyWith(events: false));
    expect(error, isA<ServerException>());
    expect(prefs().events, isTrue);
  });

  test('dil tercihi kaydedilir', () async {
    when(() => repo.updatePreferences(any())).thenAnswer((_) async => const Success(null));
    await vm.load();
    await vm.setLanguage('en');
    expect(prefs().language, 'en');
  });

  test('biyometri açmak doğrulama ister; başarısızsa açılmaz', () async {
    await vm.load();
    await vm.biometricReady;
    when(() => bio.authenticate(any())).thenAnswer((_) async => false);
    expect(await vm.toggleBiometric(on: true, reason: 'r'), BiometricToggleResult.failed);
    verifyNever(() => bio.setEnabled(value: any(named: 'value')));

    when(() => bio.authenticate(any())).thenAnswer((_) async => true);
    when(() => bio.setEnabled(value: any(named: 'value'))).thenAnswer((_) async {});
    expect(await vm.toggleBiometric(on: true, reason: 'r'), BiometricToggleResult.ok);
    verify(() => bio.setEnabled(value: true)).called(1);
  });

  test('biyometri yoksa unavailable', () async {
    when(() => bio.availableKind()).thenAnswer((_) async => null);
    await vm.load();
    await vm.biometricReady;
    expect(vm.biometricAvailable, isFalse);
    expect(await vm.toggleBiometric(on: true, reason: 'r'), BiometricToggleResult.unavailable);
  });

  test('silme talebi makbuzu / hatası iletilir', () async {
    when(() => repo.requestDeletion()).thenAnswer((_) async => Success(demoReceipt));
    expect((await vm.requestDeletion() as Success<DeleteRequestReceipt>).data.requestNo, 'KVKK-2026-048213');
    when(() => repo.requestDeletion()).thenAnswer((_) async => const Failure(ConflictException()));
    expect((await vm.requestDeletion() as Failure).error, isA<ConflictException>());
  });

  test('refreshUser maskeli özetleri tazeler', () async {
    await vm.load();
    when(() => repo.me()).thenAnswer((_) async => Success(demoUser.copyWith(phoneMasked: '0555 *** ** 12')));
    await vm.refreshUser();
    expect((vm.state as ViewSuccess<SettingsData>).data.user.phoneMasked, '0555 *** ** 12');
  });
}

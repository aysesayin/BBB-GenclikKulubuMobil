import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/profile_stats.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/user_profile.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/view_model/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

void main() {
  late MockProfileRepository repo;
  late ProfileViewModel vm;

  setUp(() {
    repo = MockProfileRepository();
    vm = ProfileViewModel(repo);
  });

  test('kullanıcı + sayaçlar yüklenir', () async {
    when(() => repo.me()).thenAnswer((_) async => const Success(demoUser));
    when(() => repo.stats()).thenAnswer((_) async => const Success(demoStats));
    await vm.load();
    final data = (vm.state as ViewSuccess<ProfileOverview>).data;
    expect(data.user.initials, 'AS');
    expect(data.stats.totalBuanEarned, 24350);
  });

  test('stats hatası ekranı düşürmez, boş sayaç gösterilir', () async {
    when(() => repo.me()).thenAnswer((_) async => const Success(demoUser));
    when(() => repo.stats()).thenAnswer((_) async => const Failure(ServerException()));
    await vm.load();
    final data = (vm.state as ViewSuccess<ProfileOverview>).data;
    expect(data.stats, const ProfileStats());
  });

  test('me hatası → hata durumu', () async {
    when(() => repo.me()).thenAnswer((_) async => const Failure(NetworkException()));
    when(() => repo.stats()).thenAnswer((_) async => const Success(demoStats));
    await vm.load();
    expect(vm.state, isA<ViewError<ProfileOverview>>());
    expect((vm.state as ViewError).isOffline, isTrue);
  });

  test('önbellekten gelen veri çevrimdışı işaretlenir', () async {
    when(() => repo.me()).thenAnswer((_) async => const Success(demoUser, fromCache: true));
    when(() => repo.stats()).thenAnswer((_) async => const Success(demoStats));
    await vm.load();
    expect((vm.state as ViewSuccess<ProfileOverview>).fromCache, isTrue);
  });

  test('çıkış: sunucu çıkışı + yerel oturum temizliği', () async {
    final session = MockSessionController();
    when(() => repo.logout()).thenAnswer((_) async => const Failure(NetworkException()));
    when(session.signOut).thenAnswer((_) async {});
    await vm.signOut(session);
    verify(() => repo.logout()).called(1);
    verify(session.signOut).called(1);
  });

  test('avatar yükleme hatası döner, başarıda profil yenilenir', () async {
    when(() => repo.me()).thenAnswer((_) async => const Success(demoUser));
    when(() => repo.stats()).thenAnswer((_) async => const Success(demoStats));
    when(
      () => repo.uploadAvatar(
        path: any(named: 'path'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => const Failure(ValidationException()));
    expect(await vm.uploadAvatar(path: '/a.jpg', fileName: 'a.jpg'), isA<ValidationException>());
    expect(vm.avatarBusy, isFalse);

    when(
      () => repo.uploadAvatar(
        path: any(named: 'path'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => const Success(null));
    expect(await vm.uploadAvatar(path: '/a.jpg', fileName: 'a.jpg'), isNull);
    verify(() => repo.me()).called(1);
  });

  test('UserProfile.displayTckn açık TCKN gelse bile maskeler', () {
    expect(const UserProfile(id: 'x', firstName: 'a', lastName: 'b', tcknMasked: '12345678901').displayTckn, '1234*****01');
    expect(demoUser.displayTckn, '1234*****90');
  });
}

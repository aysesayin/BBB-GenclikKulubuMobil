import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/card/digital_card.dart';
import 'package:bbb_genclik_kulubu_app/features/card_qr/view_model/card_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'card_mocks.dart';

void main() {
  late MockCardRepository repo;
  late DateTime now;
  const card = DigitalCard(
    firstName: 'Ayşe',
    lastName: 'Su',
    memberNo: '0016 4821',
    level: 3,
    levelName: 'Kâşif',
    maskedTckn: '1234*****90',
  );
  const token = CardToken(token: 'tok-1', pin: '8315');

  setUp(() {
    repo = MockCardRepository();
    now = DateTime(2026, 10, 16, 12);
    when(() => repo.card()).thenAnswer((_) async => const Success(card));
    when(() => repo.token()).thenAnswer((_) async => const Success(token));
  });

  CardViewModel build() => CardViewModel(repo, clock: () => now, autoTick: false);

  test('kart + token yüklenir; 30 sn geri sayım', () async {
    final vm = build();
    await vm.load();
    expect(vm.card, isA<ViewSuccess<DigitalCard>>());
    expect(vm.card.dataOrNull?.fullName, 'Ayşe Su');
    expect(vm.pin, '8315');
    expect(vm.secondsLeft, 30);
    now = now.add(const Duration(seconds: 12));
    expect(vm.secondsLeft, 18);
    expect(vm.ringValue, closeTo(.6, .001));
  });

  test('süre dolunca tick yeni token ister', () async {
    final vm = build();
    await vm.load();
    vm.setActive(true);
    now = now.add(const Duration(seconds: 31));
    when(() => repo.token()).thenAnswer((_) async => const Success(CardToken(token: 'tok-2', pin: '4402')));
    vm.tick();
    await Future<void>.delayed(Duration.zero);
    expect(vm.token?.token, 'tok-2');
    expect(vm.secondsLeft, 30);
    verify(() => repo.token()).called(2);
  });

  test('sekme gizliyken tick hiçbir şey yapmaz', () async {
    final vm = build();
    await vm.load();
    now = now.add(const Duration(seconds: 40));
    vm.tick();
    verify(() => repo.token()).called(1);
  });

  test('çevrimdışı: son geçerli kod güvenli depodan', () async {
    when(() => repo.token()).thenAnswer((_) async => const Failure(NetworkException()));
    when(() => repo.lastPin()).thenAnswer((_) async => '7719');
    final vm = build();
    await vm.load();
    expect(vm.offline, isTrue);
    expect(vm.token, isNull);
    expect(vm.pin, '7719');
  });

  test('sunucu hatası: çevrimdışı değil, kod yok', () async {
    when(() => repo.token()).thenAnswer((_) async => const Failure(ServerException()));
    final vm = build();
    await vm.load();
    expect(vm.offline, isFalse);
    expect(vm.pin, isNull);
    expect(vm.tokenError, isA<ServerException>());
    verifyNever(() => repo.lastPin());
  });

  test('geri dönünce süresi dolmuşsa yenilenir', () async {
    final vm = build();
    await vm.load();
    vm.setActive(true);
    vm.setActive(false);
    now = now.add(const Duration(minutes: 2));
    vm.setActive(true);
    await Future<void>.delayed(Duration.zero);
    verify(() => repo.token()).called(2);
  });
}

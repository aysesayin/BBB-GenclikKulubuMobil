import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_league.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/league/view_model/league_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/widgets/buan_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'buan_fixtures.dart';

void main() {
  late MockBuanRepository repo;

  setUpAll(() => registerFallbackValue(BuanLeagueScope.global));

  setUp(() {
    repo = MockBuanRepository();
    when(
      () => repo.leaderboard(
        scope: any(named: 'scope'),
        districtId: any(named: 'districtId'),
      ),
    ).thenAnswer((_) async => Success(league()));
  });

  test('podyum, liste ve KVKK kısaltılmış adlar', () async {
    final vm = LeagueViewModel(repo);
    await vm.load();
    expect(vm.podium.map((e) => e.rank), [1, 2, 3]);
    expect(vm.rest, hasLength(12));
    expect(vm.me?.rank, 14);
    expect(vm.me?.name, 'Ayşe Y.');
    expect(vm.entries.every((e) => RegExp(r'^\S+ \S\.$').hasMatch(e.name)), isTrue);
  });

  test('bölgeler: ilk 10 yükselme, son 3 düşme, arası güvenli', () async {
    final vm = LeagueViewModel(repo);
    await vm.load();
    expect(vm.zoneOf(4), LeagueZone.promotion);
    expect(vm.zoneOf(10), LeagueZone.promotion);
    expect(vm.zoneOf(11), LeagueZone.safe);
    expect(vm.zoneOf(13), LeagueZone.relegation);
    // Başlıklar: 4. (ilk liste satırı), 11. ve 13. sıranın üstünde.
    final headers = [
      for (var i = 0; i < vm.rest.length; i++)
        if (vm.zoneHeaderBefore(i) != null) vm.rest[i].rank,
    ];
    expect(headers, [4, 11, 13]);
    expect(vm.inPromotion, isFalse);
  });

  test('Arkadaşlar: mock genel veri döndürünce istemci süzer ve yeniden sıralar', () async {
    final vm = LeagueViewModel(repo);
    await vm.load();
    await vm.setScope(BuanLeagueScope.friends);
    verify(() => repo.leaderboard(scope: BuanLeagueScope.friends)).called(1);
    expect(vm.entries.map((e) => e.rank), [1, 2, 3]);
    expect(vm.entries.where((e) => e.isMe), hasLength(1));
    expect(vm.me?.rank, 3);
    expect(vm.showZones, isFalse);
    expect(vm.zoneOf(1), isNull);
  });

  test('İlçe: kullanıcının ilçesiyle istenir; ilçe değişince yeniden yüklenir', () async {
    final vm = LeagueViewModel(repo);
    await vm.load();
    await vm.setScope(BuanLeagueScope.district);
    verify(() => repo.leaderboard(scope: BuanLeagueScope.district, districtId: 'dst-nilufer')).called(1);
    expect(vm.entries, hasLength(3));
    expect(vm.districtName, 'Nilüfer');
    await vm.setDistrict('dst-osmangazi');
    verify(() => repo.leaderboard(scope: BuanLeagueScope.district, districtId: 'dst-osmangazi')).called(1);
    expect(vm.entries, hasLength(12));
    expect(vm.me, isNull, reason: 'kullanıcı bu ilçede değil');
  });

  test('sunucu istenen kapsamı döndürürse süzme yapılmaz', () async {
    when(
      () => repo.leaderboard(
        scope: BuanLeagueScope.friends,
        districtId: any(named: 'districtId'),
      ),
    ).thenAnswer((_) async => Success(league(scope: BuanLeagueScope.friends)));
    final vm = LeagueViewModel(repo);
    await vm.load();
    await vm.setScope(BuanLeagueScope.friends);
    expect(vm.entries, hasLength(15));
  });

  test('kvkkShortName', () {
    expect(kvkkShortName('Ayşe Su Yılmaz'), 'Ayşe Y.');
    expect(kvkkShortName('Mert K.'), 'Mert K.');
    expect(kvkkShortName('Deniz'), 'Deniz');
    expect(initialsOf('ilker şahin'), 'İŞ');
  });
}

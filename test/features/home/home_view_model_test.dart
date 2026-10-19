import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/home/app_link.dart';
import 'package:bbb_genclik_kulubu_app/data/models/home/home_feed.dart';
import 'package:bbb_genclik_kulubu_app/data/models/home/home_items.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/home_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/home/home_links.dart';
import 'package:bbb_genclik_kulubu_app/features/home/view_model/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockHomeRepository extends Mock implements HomeRepository {}

const _feed = HomeFeed(
  user: HomeUser(firstName: 'Ayşe', lastName: 'Su'),
  wallet: HomeWallet(balance: 12450, streak: 7),
  unreadCount: 3,
  stories: [HomeStory(id: 'sto-konser', label: 'Konser')],
  shortcuts: [
    HomeShortcut(
      id: 'sc',
      label: 'Harita',
      icon: 'map',
      link: AppLink(type: 'map'),
    ),
  ],
  league: HomeLeague(tier: 'Gümüş', rank: 14),
);

void main() {
  late _MockHomeRepository repo;

  setUp(() => repo = _MockHomeRepository());

  group('HomeViewModel.load', () {
    test('başarı → ViewSuccess', () async {
      when(() => repo.fetchHome()).thenAnswer((_) async => const Success(_feed));
      final vm = HomeViewModel(repo);
      await vm.load();
      expect(vm.state, isA<ViewSuccess<HomeFeed>>());
      expect(vm.state.dataOrNull?.wallet?.balance, 12450);
    });

    test('önbellekten gelen veri → fromCache (çevrimdışı şeridi)', () async {
      when(() => repo.fetchHome()).thenAnswer((_) async => const Success(_feed, fromCache: true));
      final vm = HomeViewModel(repo);
      await vm.load();
      expect((vm.state as ViewSuccess<HomeFeed>).fromCache, isTrue);
    });

    test('ağ hatası, önbellek yok → ViewError (isOffline)', () async {
      when(() => repo.fetchHome()).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = HomeViewModel(repo);
      await vm.load();
      final s = vm.state as ViewError<HomeFeed>;
      expect(s.isOffline, isTrue);
      expect(s.cached, isNull);
    });

    test('hata ekranından yeniden denerken hata görünümü korunur', () async {
      when(() => repo.fetchHome()).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = HomeViewModel(repo);
      await vm.load();

      final completer = Completer<ApiResult<HomeFeed>>();
      when(() => repo.fetchHome()).thenAnswer((_) => completer.future);
      final retry = vm.refresh();
      expect(vm.state, isA<ViewLoading<HomeFeed>>());
      expect(vm.retryingFrom, isNotNull);

      completer.complete(const Success(_feed));
      await retry;
      expect(vm.retryingFrom, isNull);
      expect(vm.state, isA<ViewSuccess<HomeFeed>>());
    });

    test('ilk yüklemede retryingFrom yok (skeleton gösterilir)', () async {
      final completer = Completer<ApiResult<HomeFeed>>();
      when(() => repo.fetchHome()).thenAnswer((_) => completer.future);
      final vm = HomeViewModel(repo);
      final f = vm.load();
      expect(vm.retryingFrom, isNull);
      completer.complete(const Success(_feed));
      await f;
    });
  });

  group('selam', () {
    test('saat dilimleri', () {
      expect(HomeViewModel.greetingFor(5), HomeGreeting.morning);
      expect(HomeViewModel.greetingFor(11), HomeGreeting.morning);
      expect(HomeViewModel.greetingFor(12), HomeGreeting.day);
      expect(HomeViewModel.greetingFor(18), HomeGreeting.evening);
      expect(HomeViewModel.greetingFor(22), HomeGreeting.night);
      expect(HomeViewModel.greetingFor(3), HomeGreeting.night);
    });

    test('saat kaynağı enjekte edilir', () {
      final vm = HomeViewModel(repo, clock: () => DateTime(2026, 10, 16, 9));
      expect(vm.greeting, HomeGreeting.morning);
    });
  });

  group('blocksOf', () {
    test('panel sırası yoksa varsayılan sıra, boş bloklar gizli', () {
      expect(HomeViewModel.blocksOf(_feed), [HomeBlock.stories, HomeBlock.shortcuts, HomeBlock.league]);
    });

    test('panel sırası uygulanır; bilinmeyen ve yinelenen anahtarlar atılır', () {
      final f = _feed.copyWith(blocks: ['league', 'xyz', 'stories', 'league', 'deals', 'shortcuts']);
      expect(HomeViewModel.blocksOf(f), [HomeBlock.league, HomeBlock.stories, HomeBlock.shortcuts]);
    });
  });

  test('baş harfler Türkçe büyük harfle', () {
    expect(HomeViewModel.initialsOf(const HomeUser(firstName: 'Ayşe', lastName: 'Su')), 'AS');
    expect(HomeViewModel.initialsOf(const HomeUser(firstName: 'ismail', lastName: 'ılgaz')), 'İI');
    expect(HomeViewModel.initialsOf(const HomeUser(firstName: 'Ece')), 'E');
  });

  test('lig kalan süre', () {
    expect(HomeViewModel.remaining(223200), (2, 14));
    expect(HomeViewModel.remaining(-5), (0, 0));
  });

  test('bağlantı → rota eşlemesi', () {
    expect(routeForLink(const AppLink(type: 'opportunity', id: 'opp-burulas')), '/firsat/opp-burulas');
    expect(routeForLink(const AppLink(type: 'place', id: 'plc-asik-veysel-gm')), '/yer/plc-asik-veysel-gm');
    expect(routeForLink(const AppLink(type: 'steps')), '/buan/adim');
    expect(routeForLink(const AppLink(type: 'bilinmeyen')), isNull);
    expect(isTabRoot('/buan'), isTrue);
    expect(isTabRoot('/buan/lig'), isFalse);
  });

  test('mock home.json modele çözülür', () {
    final json = jsonDecode(File('assets/mock/home.json').readAsStringSync()) as Map<String, dynamic>;
    final feed = HomeFeed.fromJson(json['data'] as Map<String, dynamic>);
    expect(feed.user?.firstName, 'Ayşe');
    expect(feed.wallet?.streak, 7);
    expect(feed.league?.rank, 14);
    expect(HomeViewModel.blocksOf(feed), HomeBlock.values);
    for (final s in feed.shortcuts) {
      expect(routeForLink(s.link), isNotNull, reason: s.id);
    }
    for (final t in feed.tasks) {
      expect(routeForLink(t.link), isNotNull, reason: t.id);
    }
  });
}

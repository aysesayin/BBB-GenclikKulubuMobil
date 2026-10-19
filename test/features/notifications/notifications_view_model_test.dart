import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/notifications/app_notification.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/notification_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/notifications/view_model/notifications_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock implements NotificationRepository {}

final _now = DateTime(2026, 10, 16, 10);

final _items = [
  AppNotification(
    id: 'n1',
    category: NotificationCategory.earn,
    title: '+750 BUAN',
    createdAt: DateTime(2026, 10, 16, 9, 12),
    unread: true,
  ),
  AppNotification(
    id: 'n2',
    category: NotificationCategory.opportunity,
    title: 'Extrempark',
    createdAt: DateTime(2026, 10, 16, 8, 30),
    unread: true,
  ),
  AppNotification(id: 'n3', category: NotificationCategory.reservation, title: 'Havuz', createdAt: DateTime(2026, 10, 15, 18, 45)),
  AppNotification(id: 'n4', category: NotificationCategory.announcement, title: 'Kış dönemi', createdAt: DateTime(2026, 10, 12, 11)),
  AppNotification(id: 'n5', category: NotificationCategory.earn, title: 'Eski', createdAt: DateTime(2026, 9, 1)),
];

void main() {
  late _MockNotificationRepository repo;

  setUpAll(() => registerFallbackValue(NotificationCategory.earn));

  setUp(() {
    repo = _MockNotificationRepository();
    when(() => repo.list(category: any(named: 'category'))).thenAnswer((_) async => Success(_items));
    when(() => repo.readAll()).thenAnswer((_) async => const Success<void>(null));
  });

  NotificationsViewModel build() => NotificationsViewModel(repo, clock: () => _now);

  test('yükleme ve gün grupları', () async {
    final vm = build();
    await vm.load();
    expect(vm.state, isA<ViewSuccess<List<AppNotification>>>());
    expect(vm.sections.map((s) => s.group), [
      NotificationGroup.today,
      NotificationGroup.yesterday,
      NotificationGroup.thisWeek,
      NotificationGroup.earlier,
    ]);
    expect(vm.sections.first.items.map((n) => n.id), ['n1', 'n2']);
    expect(vm.hasUnread, isTrue);
  });

  test('kategori seçimi sorguyla yeniden yükler ve istemcide süzer', () async {
    final vm = build();
    await vm.load();
    vm.selectCategory(NotificationCategory.earn);
    await untilCalled(() => repo.list(category: NotificationCategory.earn));
    await Future<void>.delayed(Duration.zero);
    expect(vm.category, NotificationCategory.earn);
    expect(vm.visible.map((n) => n.id), ['n1', 'n5']);

    vm.selectCategory(null);
    await Future<void>.delayed(Duration.zero);
    expect(vm.visible.length, 5);
  });

  test('tümünü okundu yap — iyimser, başarı', () async {
    final vm = build();
    await vm.load();
    expect(await vm.readAll(), isTrue);
    expect(vm.hasUnread, isFalse);
    verify(() => repo.readAll()).called(1);
    expect(await vm.readAll(), isFalse, reason: 'okunmamış kalmadı');
  });

  test('tümünü okundu yap — hata olursa geri alınır', () async {
    when(() => repo.readAll()).thenAnswer((_) async => const Failure<void>(NetworkException()));
    final vm = build();
    await vm.load();
    expect(await vm.readAll(), isFalse);
    expect(vm.hasUnread, isTrue);
  });

  test('satır açılınca okundu işaretlenir', () async {
    final vm = build();
    await vm.load();
    vm.markRead('n1');
    expect(vm.state.dataOrNull!.firstWhere((n) => n.id == 'n1').unread, isFalse);
    expect(vm.state.dataOrNull!.firstWhere((n) => n.id == 'n2').unread, isTrue);
  });

  test('groupOf sınırları', () {
    expect(NotificationsViewModel.groupOf(DateTime(2026, 10, 16, 0, 1), _now), NotificationGroup.today);
    expect(NotificationsViewModel.groupOf(DateTime(2026, 10, 15, 23, 59), _now), NotificationGroup.yesterday);
    expect(NotificationsViewModel.groupOf(DateTime(2026, 10, 10), _now), NotificationGroup.thisWeek);
    expect(NotificationsViewModel.groupOf(DateTime(2026, 10, 9), _now), NotificationGroup.earlier);
  });

  test('mock notifications.json modele çözülür', () {
    final json = jsonDecode(File('assets/mock/notifications.json').readAsStringSync()) as Map<String, dynamic>;
    final items = ((json['data'] as Map)['items'] as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    expect(items.where((n) => n.unread).length, 3);
    expect(items.first.link?.type, 'history');
  });
}

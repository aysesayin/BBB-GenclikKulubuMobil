import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_badge.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_league.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_reward.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_task.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_transaction.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_wallet.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/buan_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';

/// Sahte repository: [balanceNotifier] gerçek uygulamadaki paylaşılan bakiyeyi taklit eder.
class MockBuanRepository extends Mock implements BuanRepository {
  MockBuanRepository({int? balance}) : balanceNotifier = ValueNotifier<int?>(balance);

  final ValueNotifier<int?> balanceNotifier;

  @override
  ValueListenable<int?> get balance => balanceNotifier;
}

const wallet = BuanWallet(balance: 12450);
const level = BuanLevel(level: 3, name: 'Kâşif', nextName: 'Efsane', pointsToNext: 7550, progress: .62);
final streak = BuanStreak(days: 7, week: [BuanStreakDay(date: DateTime(2026, 10, 12), done: true)]);

BuanTask task(BuanTaskType type, {BuanTaskStatus status = BuanTaskStatus.available, String id = 't'}) =>
    BuanTask(id: id, type: type, title: type.name, points: 100, status: status);

BuanReward reward({String id = 'rwd-teleferik', int price = 8000, String cat = 'experience', bool featured = false, int? stock = 64}) =>
    BuanReward(
      id: id,
      title: 'Teleferik + sucuk ekmek',
      categoryId: cat,
      categoryLabel: 'Deneyim',
      price: price,
      stock: stock,
      featured: featured,
    );

final market = BuanMarket(
  categories: const [
    BuanRewardCategory(id: 'experience', label: 'Deneyim'),
    BuanRewardCategory(id: 'travel', label: 'Seyahat'),
  ],
  items: [
    reward(),
    reward(id: 'rwd-kapadokya', price: 40000, cat: 'travel', featured: true),
    reward(id: 'rwd-yemek', price: 25000),
  ],
);

BuanLeagueEntry entry(int rank, String name, int points, {bool me = false, bool friend = false, String district = 'dst-osmangazi'}) =>
    BuanLeagueEntry(rank: rank, userId: 'u$rank', name: name, points: points, isMe: me, isFriend: friend, districtId: district);

BuanLeague league({BuanLeagueScope scope = BuanLeagueScope.global}) {
  final entries = [
    for (var i = 1; i <= 15; i++)
      entry(
        i,
        i == 14 ? 'Ayşe Su Yılmaz' : 'Kişi $i Soyad',
        7000 - i * 100,
        me: i == 14,
        friend: i == 4 || i == 11,
        district: i == 2 || i == 6 || i == 14 ? 'dst-nilufer' : 'dst-osmangazi',
      ),
  ];
  return BuanLeague(
    scope: scope,
    tierName: 'Gümüş',
    promoteTo: 'Altın',
    relegateTo: 'Bronz',
    promoteCount: 10,
    relegateCount: 3,
    seasonEndsAt: DateTime(2026, 10, 19),
    entries: entries,
    me: entries[13],
    pointsToPromotion: 820,
    districtId: 'dst-nilufer',
    districts: const [
      BuanDistrict(id: 'dst-nilufer', name: 'Nilüfer'),
      BuanDistrict(id: 'dst-osmangazi', name: 'Osmangazi'),
    ],
  );
}

const badges = [
  BuanBadge(id: 'b1', title: 'Kilitli 1', condition: 'Gönüllü ol'),
  BuanBadge(id: 'b2', title: 'İlk Adım', earned: true),
  BuanBadge(id: 'b3', title: '7 Gün Seri', earned: true),
];

BuanTransaction tx(String id, int amount, DateTime at) => BuanTransaction(id: id, title: 'İşlem $id', amount: amount, createdAt: at);

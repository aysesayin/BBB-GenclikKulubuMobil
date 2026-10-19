import 'dart:async';

import 'package:bbb_genclik_kulubu_app/data/models/opportunities/claim.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/opportunity.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/opportunity_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockOpportunityRepository extends Mock implements OpportunityRepository {}

/// Testlerde sabit "bugün": 16 Ekim 2026.
final testNow = DateTime(2026, 10, 16, 12);

Opportunity opp(
  String id, {
  String cat = 'cat-eglence',
  bool fav = false,
  bool isNew = false,
  int? dist,
  int daysLeft = 20,
  int remaining = 50,
  int total = 100,
  ClaimType type = ClaimType.qr,
}) => Opportunity(
  id: id,
  title: 'Başlık $id',
  brand: 'Marka $id',
  logoText: 'LG',
  categoryId: cat,
  discountLabel: '%10',
  claimType: type,
  distanceMeters: dist,
  endsAt: testNow.add(Duration(days: daysLeft)),
  stockRemaining: remaining,
  stockTotal: total,
  isFavorite: fav,
  isNew: isNew,
);

final demoList = [
  opp('opp-burulas', cat: 'cat-ulasim', fav: true, daysLeft: 12),
  opp('opp-extrempark', dist: 2400, daysLeft: 5, remaining: 18, total: 200, type: ClaimType.pnr),
  opp('opp-kitapduragi', cat: 'cat-kitap', dist: 1100, daysLeft: 31, type: ClaimType.code),
  opp('opp-kafe', cat: 'cat-yemek', dist: 650, daysLeft: 3, isNew: true),
];

ClaimResult claimOf(String id, {ClaimType type = ClaimType.pnr}) => ClaimResult(
  opportunityId: id,
  type: type,
  qr: 'GK-PNR-K7Q2M8',
  pin: type == ClaimType.code ? null : 'K7Q2M8',
  code: type == ClaimType.code ? 'EXT-7K2Q-91' : null,
  expiresAt: DateTime.now().add(const Duration(hours: 47)),
  buanReward: 100,
  brand: 'Extrempark',
  logoText: 'EXT',
  title: 'Tırmanma duvarı · 1+1',
);

OpportunityDetail detailOf(Opportunity o, {bool eligible = true, int? minAge = 16, int? maxAge = 30, String? reason}) => OpportunityDetail(
  summary: o,
  categoryName: 'Eğlence',
  minAge: minAge,
  maxAge: maxAge,
  buanReward: 100,
  steps: const ['Adım 1', 'Adım 2', 'Adım 3'],
  conditions: const ['Şart 1'],
  validity: const ['21 Ekim 2026'],
  eligible: eligible,
  ineligibleReason: reason,
);

final walletItems = [
  WalletItem(id: 'w1', opportunityId: 'opp-extrempark', status: WalletStatus.active, claim: claimOf('opp-extrempark')),
  const WalletItem(id: 'w2', opportunityId: 'opp-burulas', status: WalletStatus.active),
  const WalletItem(id: 'w3', opportunityId: 'opp-teleferik', status: WalletStatus.used, buanEarned: 100),
  const WalletItem(id: 'w4', opportunityId: 'opp-sinema', status: WalletStatus.expired),
];

/// events akışı stub'lı sahte repository.
(MockOpportunityRepository, StreamController<OpportunityEvent>) mockRepo() {
  final repo = MockOpportunityRepository();
  final events = StreamController<OpportunityEvent>.broadcast();
  when(() => repo.events).thenAnswer((_) => events.stream);
  return (repo, events);
}

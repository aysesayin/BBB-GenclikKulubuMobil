import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/network/dio_client.dart';
import 'package:bbb_genclik_kulubu_app/data/models/card/digital_card.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/claim.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/opportunity.dart';
import 'package:flutter_test/flutter_test.dart';

/// assets/mock dosyaları modellere hatasız çözülmeli (mock demo güvencesi).
void main() {
  Object? data(String name) => (jsonDecode(File('assets/mock/$name').readAsStringSync()) as Map)['data'];

  const ids = ['opp-burulas', 'opp-extrempark', 'opp-kitapduragi', 'opp-teleferik', 'opp-dilokulu', 'opp-kafe'];

  test('liste + kategoriler', () {
    final list = Json.list(data('opportunities.json'), Opportunity.fromJson);
    expect(list.map((o) => o.id), ids);
    expect(Json.list(data('opportunities.categories.json'), OpportunityCategory.fromJson), isNotEmpty);
  });

  test('detay + yakalama her fırsat için', () {
    for (final id in ids) {
      final d = OpportunityDetail.fromJson(Json.map(data('opportunities.$id.json')));
      expect(d.summary.id, id);
      final c = ClaimResult.fromJson(Json.map(data('opportunities.$id.claim.post.json')));
      expect(c.opportunityId, id);
      expect(c.type == ClaimType.code ? c.code : c.pin, isNotNull);
    }
    expect(OpportunityDetail.fromJson(Json.map(data('opportunities.opp-dilokulu.json'))).eligible, isFalse);
  });

  test('cüzdan', () {
    final mine = Json.list(data('opportunities.mine.json'), WalletItem.fromJson);
    expect(mine.where((w) => w.status == WalletStatus.active).every((w) => w.claim != null), isTrue);
  });

  test('kart, token, check-in', () {
    expect(DigitalCard.fromJson(Json.map(data('users.me.card.json'))).maskedTckn, '1234*****90');
    expect(CardToken.fromJson(Json.map(data('users.me.card.token.json'))).pin, hasLength(4));
    expect(QrCheckInResult.fromJson(Json.map(data('buan.qr-checkin.post.json'))).buan, 300);
  });
}

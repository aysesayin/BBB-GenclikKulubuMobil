import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/opportunity.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/view_model/opportunity_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'opp_fixtures.dart';

void main() {
  late MockOpportunityRepository repo;
  const id = 'opp-extrempark';

  setUp(() => (repo, _) = mockRepo());

  OpportunityDetailViewModel build(OpportunityDetail d) {
    when(() => repo.detail(id)).thenAnswer((_) async => Success(d));
    return OpportunityDetailViewModel(repo, id, clock: () => testNow);
  }

  test('detay yüklenir, CTA uygun', () async {
    final vm = build(detailOf(opp(id, daysLeft: 5)));
    await vm.load();
    expect(vm.state, isA<ViewSuccess<OpportunityDetail>>());
    expect(vm.cta, ClaimCta.available);
    expect(vm.daysLeft(), 5);
    expect(vm.endingSoon, isTrue);
  });

  test('yaş uygunsuzsa CTA pasif', () async {
    final vm = build(detailOf(opp(id), eligible: false, reason: '18–30 yaş'));
    await vm.load();
    expect(vm.cta, ClaimCta.ineligible);
  });

  test('stok bitince CTA pasif', () async {
    final vm = build(detailOf(opp(id, remaining: 0)));
    await vm.load();
    expect(vm.cta, ClaimCta.soldOut);
  });

  test('yakalama başarılı → claim saklanır, CTA "Kodumu göster"', () async {
    final vm = build(detailOf(opp(id)));
    await vm.load();
    when(() => repo.claim(id)).thenAnswer((_) async => Success(claimOf(id)));
    final r = await vm.claimNow();
    expect(r, isA<Success<Object?>>());
    expect(vm.claim?.opportunityId, id);
    expect(vm.cta, ClaimCta.claimed);
    expect(vm.claiming, isFalse);
  });

  test('yakalama çakışması (409) hata döner', () async {
    final vm = build(detailOf(opp(id)));
    await vm.load();
    when(() => repo.claim(id)).thenAnswer((_) async => const Failure(ConflictException()));
    final r = await vm.claimNow();
    expect((r as Failure).error, isA<ConflictException>());
    expect(vm.cta, ClaimCta.available);
  });

  test('favori iyimser, hata olursa geri döner', () async {
    final vm = build(detailOf(opp(id)));
    await vm.load();
    when(() => repo.setFavorite(id, value: true)).thenAnswer((_) async => const Failure(ServerException()));
    final f = vm.toggleFavorite();
    expect(vm.isFavorite, isTrue);
    expect(await f, isA<ServerException>());
    expect(vm.isFavorite, isFalse);
  });

  test('akordeon: tek bölüm açık, tekrar dokununca kapanır', () async {
    final vm = build(detailOf(opp(id)));
    expect(vm.expanded, 0);
    vm.toggleSection(2);
    expect(vm.expanded, 2);
    vm.toggleSection(2);
    expect(vm.expanded, -1);
  });
}

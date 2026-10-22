import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/claim.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/view_model/claimed_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/view_model/rating_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'opp_fixtures.dart';

void main() {
  late MockOpportunityRepository repo;
  const id = 'opp-extrempark';

  setUp(() => (repo, _) = mockRepo());

  group('RatingViewModel', () {
    test('yıldız seçilmeden gönderilemez; 1–5 aralığına kırpılır', () {
      final vm = RatingViewModel(repo, id);
      expect(vm.canSubmit, isFalse);
      vm.setStars(9);
      expect(vm.stars, 5);
      vm.setStars(3);
      expect(vm.canSubmit, isTrue);
    });

    test('gönderim: yorum kırpılır, sonuç + BUAN gelir, tekrar gönderilemez', () async {
      when(
        () => repo.rate(id, stars: 4, comment: 'Harika'),
      ).thenAnswer((_) async => const Success(RatingResult(opportunityId: id, buanReward: 100, label: 'Fırsat Kullan Kazan')));
      final vm = RatingViewModel(repo, id);
      vm.setStars(4);
      vm.setComment('  Harika  ');
      expect(await vm.submit(), isNull);
      expect(vm.result?.buanReward, 100);
      expect(vm.result?.label, 'Fırsat Kullan Kazan');
      expect(vm.submitting, isFalse);
      expect(vm.canSubmit, isFalse);
      expect(await vm.submit(), isNull);
      verify(() => repo.rate(id, stars: 4, comment: 'Harika')).called(1);
    });

    test('boş yorum null gider; hata döner ve tekrar denenebilir', () async {
      when(() => repo.rate(id, stars: 2, comment: null)).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = RatingViewModel(repo, id);
      vm.setStars(2);
      vm.setComment('   ');
      expect(await vm.submit(), isA<NetworkException>());
      expect(vm.result, isNull);
      expect(vm.canSubmit, isTrue);
    });

    test('yorum üst sınırı', () {
      final vm = RatingViewModel(repo, id);
      vm.setComment('a' * 500);
      expect(vm.comment.length, RatingViewModel.maxComment);
    });
  });

  group('ClaimedViewModel · kullanıldı', () {
    test('markUsed bir kez puanlama ister', () {
      final vm = ClaimedViewModel(repo, id, initial: claimOf(id));
      expect(vm.used, isFalse);
      expect(vm.takeRatingPrompt(), isFalse, reason: 'henüz kullanılmadı');
      vm.markUsed();
      expect(vm.used, isTrue);
      expect(vm.takeRatingPrompt(), isTrue);
      expect(vm.takeRatingPrompt(), isFalse, reason: 'ikinci kez açılmaz');
      vm.markUsed();
      expect(vm.used, isTrue);
    });
  });
}

import 'package:bbb_genclik_kulubu_app/core/network/api_endpoints.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/referral.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/buan_tasks_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/invite/view_model/invite_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements ReferralRepository {}

void main() {
  late _Repo repo;

  setUp(() => repo = _Repo());

  test('deep link ve haftalık hak', () async {
    when(
      () => repo.referral(),
    ).thenAnswer((_) async => const Success(Referral(code: 'AYSE-7K2', inviterReward: 2000, inviteeReward: 500, weeklyUsed: 1)));
    final vm = InviteViewModel(repo);
    await vm.load();
    expect(vm.link, '${ApiConfig.deepLinkBase}/davet/AYSE-7K2');
    expect(vm.limitReached, isTrue);
    expect(vm.remainingThisWeek, 0);
    vm.dispose();
  });

  test('hak kaldıysa limit dolmamıştır', () async {
    when(
      () => repo.referral(),
    ).thenAnswer((_) async => const Success(Referral(code: 'X', inviterReward: 2000, inviteeReward: 500, weeklyLimit: 2)));
    final vm = InviteViewModel(repo);
    await vm.load();
    expect(vm.limitReached, isFalse);
    expect(vm.remainingThisWeek, 2);
    vm.dispose();
  });

  test('kopyalandı işareti süre sonunda kalkar', () async {
    when(() => repo.referral()).thenAnswer((_) async => const Success(Referral(code: 'X', inviterReward: 1, inviteeReward: 1)));
    final vm = InviteViewModel(repo, copiedDuration: const Duration(milliseconds: 10));
    await vm.load();
    vm.markCopied();
    expect(vm.copied, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(vm.copied, isFalse);
    vm.dispose();
  });

  test('yüklenmeden bağlantı boş', () {
    final vm = InviteViewModel(repo);
    expect(vm.link, isEmpty);
    expect(vm.limitReached, isFalse);
    vm.dispose();
  });
}

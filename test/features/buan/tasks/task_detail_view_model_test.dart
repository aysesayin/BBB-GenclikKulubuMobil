import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_endpoints.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_task.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/detail/view_model/task_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../buan_fixtures.dart';

void main() {
  late MockBuanRepository repo;

  setUp(() {
    repo = MockBuanRepository(balance: 12450);
    when(() => repo.tasks()).thenAnswer(
      (_) async => Success([
        BuanTaskGroup(
          id: 'once',
          title: 'Tek Seferlik',
          tasks: [
            task(BuanTaskType.follow, id: 'tsk-follow'),
            task(BuanTaskType.volunteer, id: 'tsk-volunteer'),
            task(BuanTaskType.biko, id: 'tsk-biko'),
            task(BuanTaskType.idea, id: 'tsk-idea'),
            task(BuanTaskType.useOpportunity, id: 'tsk-opp'),
            task(BuanTaskType.unknown, id: 'tsk-unknown'),
            task(BuanTaskType.follow, id: 'tsk-locked', status: BuanTaskStatus.locked),
            task(BuanTaskType.volunteer, id: 'tsk-pending', status: BuanTaskStatus.pending),
          ],
        ),
      ]),
    );
    when(
      () => repo.completeTask(any(), declared: any(named: 'declared')),
    ).thenAnswer((_) async => const Success(TaskCompleteResult(status: BuanTaskStatus.pending)));
  });

  Future<TaskDetailViewModel> load(String id) async {
    final vm = TaskDetailViewModel(repo, taskId: id);
    await vm.load();
    return vm;
  }

  test('görevi listeden id ile bulur', () async {
    final vm = await load('tsk-follow');
    expect(vm.task?.id, 'tsk-follow');
    expect(vm.state, isA<ViewSuccess<BuanTask>>());
  });

  test('listede yoksa NotFound hatası', () async {
    final vm = await load('tsk-yok');
    expect((vm.state as ViewError<BuanTask>).error, isA<NotFoundException>());
  });

  test('liste hatası aynen geçer', () async {
    when(() => repo.tasks()).thenAnswer((_) async => const Failure(NetworkException()));
    final vm = await load('tsk-follow');
    expect((vm.state as ViewError<BuanTask>).isOffline, isTrue);
  });

  test('türe göre ana eylem', () async {
    expect((await load('tsk-follow')).primaryAction, TaskPrimaryAction.declare);
    expect((await load('tsk-volunteer')).primaryAction, TaskPrimaryAction.apply);
    expect((await load('tsk-biko')).primaryAction, TaskPrimaryAction.openBiko);
    expect((await load('tsk-idea')).primaryAction, TaskPrimaryAction.openIdea);
    expect((await load('tsk-opp')).primaryAction, TaskPrimaryAction.openOpportunities);
    expect((await load('tsk-unknown')).primaryAction, TaskPrimaryAction.none);
    expect((await load('tsk-locked')).primaryAction, TaskPrimaryAction.none);
    expect((await load('tsk-pending')).primaryAction, TaskPrimaryAction.none);
  });

  test('takip beyanı: declared=true gönderir, durum pending olur', () async {
    final vm = await load('tsk-follow');
    expect(await vm.complete(), isTrue);
    verify(() => repo.completeTask('tsk-follow', declared: true)).called(1);
    expect(vm.task?.status, BuanTaskStatus.pending);
    expect(vm.primaryAction, TaskPrimaryAction.none);
    expect(vm.submitting, isFalse);
  });

  test('gönüllü başvurusu: declared=false', () async {
    final vm = await load('tsk-volunteer');
    expect(await vm.complete(), isTrue);
    verify(() => repo.completeTask('tsk-volunteer', declared: false)).called(1);
    expect(vm.task?.status, BuanTaskStatus.pending);
  });

  test('sunucu hatası: durum değişmez, error dolar ve temizlenir', () async {
    when(
      () => repo.completeTask(any(), declared: any(named: 'declared')),
    ).thenAnswer((_) async => const Failure(ConflictException()));
    final vm = await load('tsk-follow');
    expect(await vm.complete(), isFalse);
    expect(vm.error, isA<ConflictException>());
    expect(vm.task?.status, BuanTaskStatus.available);
    vm.clearError();
    expect(vm.error, isNull);
  });

  test('çift dokunuş: gönderim sürerken ikinci çağrı yok sayılır', () async {
    final vm = await load('tsk-follow');
    final first = vm.complete();
    expect(await vm.complete(), isFalse);
    await first;
    verify(() => repo.completeTask(any(), declared: any(named: 'declared'))).called(1);
  });

  test('BİKO adresi ve Fikir rotası sabitlerden gelir', () async {
    final vm = await load('tsk-biko');
    expect(vm.bikoUri.toString(), ApiEndpoints.bikoUrl);
    expect(TaskDetailViewModel.ideaRoute, startsWith(Routes.photoReport));
    expect(TaskDetailViewModel.ideaRoute, contains('tur=idea'));
  });
}

import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/quiz.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/buan_tasks_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/quiz/view_model/quiz_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements QuizRepository {}

const _opts = [QuizOption(id: 'a', label: '12'), QuizOption(id: 'b', label: '16'), QuizOption(id: 'c', label: '20')];
const _quiz = Quiz(
  id: 'qz',
  title: 'Bursa Bilgi',
  reward: 100,
  remainingThisWeek: 2,
  questions: [
    QuizQuestion(id: 'q1', text: '?', options: _opts),
    QuizQuestion(id: 'q2', text: '?', options: _opts),
  ],
);

void main() {
  late _Repo repo;
  late QuizViewModel vm;
  var t = DateTime(2026, 10, 16, 12);

  setUp(() {
    repo = _Repo();
    t = DateTime(2026, 10, 16, 12);
    vm = QuizViewModel(repo, clock: () => t);
    when(() => repo.active()).thenAnswer((_) async => const Success(_quiz));
    when(
      () => repo.answer(
        any(),
        questionId: any(named: 'questionId'),
        optionId: any(named: 'optionId'),
        elapsedMs: any(named: 'elapsedMs'),
      ),
    ).thenAnswer((_) async => const Success(QuizAnswerResult(correctOptionId: 'c', awarded: 100)));
  });

  test('doğru cevap → yeşil işaret, ödül toplanır, süre gönderilir', () async {
    await vm.load();
    t = t.add(const Duration(seconds: 4));
    await vm.answer('c');
    expect(vm.isCorrect, isTrue);
    expect(vm.markOf('c'), OptionMark.correct);
    expect(vm.markOf('a'), OptionMark.idle);
    expect(vm.correctCount, 1);
    expect(vm.awardedTotal, 100);
    verify(() => repo.answer('qz', questionId: 'q1', optionId: 'c', elapsedMs: 4000)).called(1);
  });

  test('yanlış cevap → kırmızı + doğru seçenek gösterilir, ödül yok', () async {
    await vm.load();
    await vm.answer('a');
    expect(vm.isCorrect, isFalse);
    expect(vm.markOf('a'), OptionMark.wrong);
    expect(vm.markOf('c'), OptionMark.correct);
    expect(vm.correctLabel, '20');
    expect(vm.awardedTotal, 0);
  });

  test('sunucunun correct alanı önceliklidir', () async {
    when(
      () => repo.answer(
        any(),
        questionId: any(named: 'questionId'),
        optionId: any(named: 'optionId'),
        elapsedMs: any(named: 'elapsedMs'),
      ),
    ).thenAnswer((_) async => const Success(QuizAnswerResult(correctOptionId: 'c', correct: false, awarded: 0)));
    await vm.load();
    await vm.answer('c');
    expect(vm.isCorrect, isFalse);
  });

  test('süre dolunca seçimsiz gönderilir; ikinci cevap yok sayılır', () async {
    await vm.load();
    await vm.timeUp();
    expect(vm.timedOut, isTrue);
    expect(vm.answered, isTrue);
    await vm.answer('c');
    verify(
      () => repo.answer(
        'qz',
        questionId: 'q1',
        optionId: null,
        elapsedMs: any(named: 'elapsedMs'),
      ),
    ).called(1);
    verifyNever(
      () => repo.answer(
        any(),
        questionId: any(named: 'questionId'),
        optionId: 'c',
        elapsedMs: any(named: 'elapsedMs'),
      ),
    );
  });

  test('sonraki soru ve bitiş', () async {
    await vm.load();
    vm.next();
    expect(vm.index, 0, reason: 'cevaplanmadan geçilmez');
    await vm.answer('c');
    vm.next();
    expect(vm.index, 1);
    expect(vm.answered, isFalse);
    expect(vm.isLast, isTrue);
    await vm.answer('c');
    vm.next();
    expect(vm.finished, isTrue);
    expect(vm.correctCount, 2);
    expect(vm.awardedTotal, 200);
  });

  test('gönderim hatası seçimi geri alır', () async {
    when(
      () => repo.answer(
        any(),
        questionId: any(named: 'questionId'),
        optionId: any(named: 'optionId'),
        elapsedMs: any(named: 'elapsedMs'),
      ),
    ).thenAnswer((_) async => const Failure(NetworkException()));
    await vm.load();
    await vm.answer('a');
    expect(vm.answered, isFalse);
    expect(vm.picked, isNull);
    expect(vm.error, isA<NetworkException>());
  });

  test('hak kalmadıysa / quiz yoksa boş durum', () async {
    when(() => repo.active()).thenAnswer((_) async => const Success(null));
    await vm.load();
    expect(vm.state, isA<ViewEmpty<Quiz?>>());
    when(() => repo.active()).thenAnswer((_) async => Success(_quiz.copyWith(remainingThisWeek: 0)));
    await vm.load();
    expect(vm.state, isA<ViewEmpty<Quiz?>>());
  });
}

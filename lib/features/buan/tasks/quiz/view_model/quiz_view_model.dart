import '../../../../../core/base/base_view_model.dart';
import '../../../../../core/network/api_result.dart';
import '../../../../../core/network/app_exception.dart';
import '../../../../../data/models/buan_tasks/quiz.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';

enum OptionMark { idle, correct, wrong }

/// E10 · Cevapla Kazan. Doğru cevabı yalnız sunucu bilir; istemci seçimi ve
/// süreyi gönderir, sunucunun kararını (renk + ikon) gösterir.
// TODO(varsayım): BUAN soru başına (doğru cevapta yanıtın `awarded` alanı) verilir; özet ekranı toplamı gösterir.
class QuizViewModel extends LoadableViewModel<Quiz?> {
  QuizViewModel(this._repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final QuizRepository _repo;
  final DateTime Function() _clock;

  int _index = 0;
  String? _picked;
  QuizAnswerResult? _result;
  bool _submitting = false;
  bool _timedOut = false;
  bool _finished = false;
  int _correct = 0;
  int _awarded = 0;
  DateTime _startedAt = DateTime.now();
  AppException? _error;

  Quiz? get quiz => state.dataOrNull;
  int get index => _index;
  int get total => quiz?.questions.length ?? 0;
  QuizQuestion? get question => (quiz == null || _index >= total) ? null : quiz!.questions[_index];
  String? get picked => _picked;
  QuizAnswerResult? get result => _result;
  bool get answered => _result != null;
  bool get submitting => _submitting;
  bool get timedOut => _timedOut;
  bool get finished => _finished;
  int get correctCount => _correct;
  int get awardedTotal => _awarded;
  bool get isLast => _index >= total - 1;
  AppException? get error => _error;

  /// Sunucu kararı; yoksa seçim ile doğru seçenek karşılaştırılır.
  bool get isCorrect => _result != null && (_result!.correct ?? (_picked != null && _picked == _result!.correctOptionId));

  @override
  Future<ApiResult<Quiz?>> fetch() => _repo.active();

  @override
  bool isEmpty(Quiz? data) => data == null || data.questions.isEmpty || data.remainingThisWeek <= 0;

  @override
  Future<void> load() async {
    await super.load();
    _index = 0;
    _correct = 0;
    _awarded = 0;
    _finished = false;
    _resetQuestion();
    notify();
  }

  void _resetQuestion() {
    _picked = null;
    _result = null;
    _timedOut = false;
    _startedAt = _clock();
  }

  Future<void> answer(String optionId) => _submit(optionId);

  /// Süre doldu → seçimsiz gönderilir (sunucu doğru cevabı döner).
  Future<void> timeUp() async {
    if (answered || _submitting) return;
    _timedOut = true;
    await _submit(null);
  }

  Future<void> _submit(String? optionId) async {
    final q = question, z = quiz;
    if (q == null || z == null || answered || _submitting) return;
    _picked = optionId;
    _submitting = true;
    notify();
    final elapsed = _clock().difference(_startedAt).inMilliseconds;
    final r = await _repo.answer(z.id, questionId: q.id, optionId: optionId, elapsedMs: elapsed);
    if (isDisposed) return;
    _submitting = false;
    switch (r) {
      case Success(:final data):
        _result = data;
        if (isCorrect) {
          _correct++;
          _awarded += data.awarded;
        }
      case Failure(:final error):
        _picked = null;
        _timedOut = false;
        _error = error;
    }
    notify();
  }

  OptionMark markOf(String optionId) {
    final r = _result;
    if (r == null) return OptionMark.idle;
    if (optionId == r.correctOptionId) return OptionMark.correct;
    if (optionId == _picked) return OptionMark.wrong;
    return OptionMark.idle;
  }

  String? get correctLabel {
    final id = _result?.correctOptionId;
    for (final o in question?.options ?? const <QuizOption>[]) {
      if (o.id == id) return o.label;
    }
    return null;
  }

  void next() {
    if (!answered) return;
    if (isLast) {
      _finished = true;
    } else {
      _index++;
      _resetQuestion();
    }
    notify();
  }

  void clearError() => _error = null;
}

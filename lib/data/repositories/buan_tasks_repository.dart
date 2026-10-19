import '../../core/network/api_result.dart';
import '../models/buan_tasks/daily_spin.dart';
import '../models/buan_tasks/photo_report.dart';
import '../models/buan_tasks/quiz.dart';
import '../models/buan_tasks/referral.dart';
import '../models/buan_tasks/steps.dart';
import '../models/buan_tasks/watch_video.dart';
import '../services/buan_tasks_service.dart';

/// E7 · Günlük Şans.
abstract interface class DailySpinRepository {
  Future<ApiResult<DailySpinStatus>> status();

  /// Sonuç sunucuda belirlenir. [idempotencyKey] çift dokunuşu engeller.
  Future<ApiResult<SpinResult>> spin(String idempotencyKey);
}

/// E8 · İzle Kazan.
abstract interface class WatchEarnRepository {
  Future<ApiResult<WatchVideo>> current();
  Future<ApiResult<void>> heartbeat(String videoId, {required int positionSec, required int watchedSec});
  Future<ApiResult<VideoCompleteResult>> complete(String videoId, {required int watchedSec});
}

/// E9 · Bir Adım At.
abstract interface class StepsRepository {
  Future<ApiResult<StepsSummary>> summary();

  /// `{date: yyyy-MM-dd, steps}` — sunucu günlük üst limiti uygular.
  Future<ApiResult<StepsSummary>> report({required String date, required int steps});
}

/// E10 · Cevapla Kazan.
abstract interface class QuizRepository {
  /// Bu hafta oynanabilir quiz yoksa `Success(null)`.
  Future<ApiResult<Quiz?>> active();
  Future<ApiResult<QuizAnswerResult>> answer(String quizId, {required String questionId, String? optionId, required int elapsedMs});
}

/// E11 · Davet Et.
abstract interface class ReferralRepository {
  Future<ApiResult<Referral>> referral();
}

/// E12 · Çek Kazan.
abstract interface class PhotoReportRepository {
  Future<ApiResult<List<PhotoReportType>>> types();
  Future<ApiResult<List<PhotoReport>>> mine();
  Future<ApiResult<PhotoReport>> submit(PhotoReportDraft draft);
}

class DailySpinRepositoryImpl implements DailySpinRepository {
  DailySpinRepositoryImpl(this._s);
  final BuanTasksService _s;

  @override
  Future<ApiResult<DailySpinStatus>> status() => _s.spinStatus();
  @override
  Future<ApiResult<SpinResult>> spin(String idempotencyKey) => _s.spin(idempotencyKey);
}

class WatchEarnRepositoryImpl implements WatchEarnRepository {
  WatchEarnRepositoryImpl(this._s);
  final BuanTasksService _s;

  @override
  Future<ApiResult<WatchVideo>> current() => _s.currentVideo();
  @override
  Future<ApiResult<void>> heartbeat(String videoId, {required int positionSec, required int watchedSec}) =>
      _s.videoHeartbeat(videoId, positionSec: positionSec, watchedSec: watchedSec);
  @override
  Future<ApiResult<VideoCompleteResult>> complete(String videoId, {required int watchedSec}) => _s.completeVideo(videoId, watchedSec: watchedSec);
}

class StepsRepositoryImpl implements StepsRepository {
  StepsRepositoryImpl(this._s);
  final BuanTasksService _s;

  @override
  Future<ApiResult<StepsSummary>> summary() => _s.steps();
  @override
  Future<ApiResult<StepsSummary>> report({required String date, required int steps}) => _s.reportSteps(date: date, steps: steps);
}

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._s);
  final BuanTasksService _s;

  @override
  Future<ApiResult<Quiz?>> active() => _s.activeQuiz();
  @override
  Future<ApiResult<QuizAnswerResult>> answer(String quizId, {required String questionId, String? optionId, required int elapsedMs}) =>
      _s.answer(quizId, questionId: questionId, optionId: optionId, elapsedMs: elapsedMs);
}

class ReferralRepositoryImpl implements ReferralRepository {
  ReferralRepositoryImpl(this._s);
  final BuanTasksService _s;

  @override
  Future<ApiResult<Referral>> referral() => _s.referral();
}

class PhotoReportRepositoryImpl implements PhotoReportRepository {
  PhotoReportRepositoryImpl(this._s);
  final BuanTasksService _s;

  @override
  Future<ApiResult<List<PhotoReportType>>> types() => _s.reportTypes();
  @override
  Future<ApiResult<List<PhotoReport>>> mine() => _s.myReports();
  @override
  Future<ApiResult<PhotoReport>> submit(PhotoReportDraft draft) => _s.submitReport(draft);
}

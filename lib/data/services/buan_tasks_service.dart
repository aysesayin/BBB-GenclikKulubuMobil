import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/buan_tasks/daily_spin.dart';
import '../models/buan_tasks/photo_report.dart';
import '../models/buan_tasks/quiz.dart';
import '../models/buan_tasks/referral.dart';
import '../models/buan_tasks/steps.dart';
import '../models/buan_tasks/watch_video.dart';

/// BUAN görevleri (E7–E12) uç noktaları. Puanlama tamamen sunucudadır;
/// istemci yalnız ilerleme bildirir ve sunucunun sonucunu gösterir.
class BuanTasksService {
  BuanTasksService(this._client);

  final DioClient _client;

  // E7 · Günlük Şans
  Future<ApiResult<DailySpinStatus>> spinStatus() => _client.get(ApiEndpoints.dailySpin, parse: (d) => DailySpinStatus.fromJson(Json.map(d)));

  Future<ApiResult<SpinResult>> spin(String idempotencyKey) =>
      _client.post(ApiEndpoints.dailySpin, parse: (d) => SpinResult.fromJson(Json.map(d)), headers: {'Idempotency-Key': idempotencyKey});

  // E8 · İzle Kazan
  Future<ApiResult<WatchVideo>> currentVideo() =>
      _client.get(ApiEndpoints.watchVideo, parse: (d) => WatchVideo.fromJson(Json.map(d)), cacheKey: 'buan.video');

  Future<ApiResult<void>> videoHeartbeat(String id, {required int positionSec, required int watchedSec}) =>
      _client.post(ApiEndpoints.videoProgress(id), parse: Json.ignore, body: {'positionSec': positionSec, 'watchedSec': watchedSec});

  Future<ApiResult<VideoCompleteResult>> completeVideo(String id, {required int watchedSec}) => _client.post(
    ApiEndpoints.videoComplete(id),
    parse: (d) => VideoCompleteResult.fromJson(Json.map(d)),
    body: {'watchedSec': watchedSec},
    headers: {'Idempotency-Key': 'video-$id'},
  );

  // E9 · Bir Adım At
  Future<ApiResult<StepsSummary>> steps() =>
      _client.get(ApiEndpoints.steps, parse: (d) => StepsSummary.fromJson(Json.map(d)), cacheKey: 'buan.steps');

  Future<ApiResult<StepsSummary>> reportSteps({required String date, required int steps}) =>
      _client.post(ApiEndpoints.steps, parse: (d) => StepsSummary.fromJson(Json.map(d)), body: {'date': date, 'steps': steps});

  // E10 · Cevapla Kazan
  Future<ApiResult<Quiz?>> activeQuiz() => _client.get(ApiEndpoints.quizActive, parse: (d) => d == null ? null : Quiz.fromJson(Json.map(d)));

  Future<ApiResult<QuizAnswerResult>> answer(String quizId, {required String questionId, String? optionId, required int elapsedMs}) => _client.post(
    ApiEndpoints.quizAnswer(quizId),
    parse: (d) => QuizAnswerResult.fromJson(Json.map(d)),
    body: {'questionId': questionId, 'optionId': optionId, 'elapsedMs': elapsedMs},
  );

  // E11 · Davet Et
  Future<ApiResult<Referral>> referral() =>
      _client.get(ApiEndpoints.referral, parse: (d) => Referral.fromJson(Json.map(d)), cacheKey: 'buan.referral');

  // E12 · Çek Kazan
  Future<ApiResult<List<PhotoReportType>>> reportTypes() =>
      _client.get(ApiEndpoints.photoReportTypes, parse: (d) => Json.list(d, PhotoReportType.fromJson), cacheKey: 'photoReport.types');

  Future<ApiResult<List<PhotoReport>>> myReports() => _client.get(ApiEndpoints.myPhotoReports, parse: (d) => Json.list(d, PhotoReport.fromJson));

  // TODO(varsayım): "Fikir" sekmesi de /photo-reports'a type=idea (fotoğrafsız) gider; ApiEndpoints.ideas başka akışa ait sayıldı.
  Future<ApiResult<PhotoReport>> submitReport(PhotoReportDraft draft) {
    final form = FormData.fromMap({
      'type': draft.typeId,
      'category': draft.categoryId,
      'note': draft.note,
      if (draft.latitude != null) 'lat': draft.latitude,
      if (draft.longitude != null) 'lng': draft.longitude,
      if (draft.photo != null) 'photo': MultipartFile.fromBytes(draft.photo!, filename: draft.photoName ?? 'photo.jpg'),
    });
    return _client.upload(ApiEndpoints.photoReports, parse: (d) => PhotoReport.fromJson(Json.map(d)), form: form);
  }
}

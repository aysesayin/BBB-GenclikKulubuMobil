import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/network/dio_client.dart';
import 'package:bbb_genclik_kulubu_app/core/network/interceptors/mock_interceptor.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/daily_spin.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/photo_report.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/quiz.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/referral.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/steps.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/watch_video.dart';
import 'package:bbb_genclik_kulubu_app/data/models/games/game.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _data(String file) => (jsonDecode(File('assets/mock/$file').readAsStringSync()) as Map)['data'];

/// Mock dosyaları modellerle uyumlu mu ve MockInterceptor bunları buluyor mu?
void main() {
  test('mock JSON → model', () {
    expect(DailySpinStatus.fromJson(Json.map(_data('buan.daily-spin.json'))).slices, hasLength(8));
    expect(SpinResult.fromJson(Json.map(_data('buan.daily-spin.post.json'))).sliceIndex, 1);
    expect(WatchVideo.fromJson(Json.map(_data('buan.videos.current.json'))).reward, 1000);
    expect(VideoCompleteResult.fromJson(Json.map(_data('buan.videos._.complete.post.json'))).awarded, 1000);
    expect(StepsSummary.fromJson(Json.map(_data('buan.steps.json'))).week, hasLength(6));
    expect(StepsSummary.fromJson(Json.map(_data('buan.steps.post.json'))).awarded, 750);
    final quiz = Quiz.fromJson(Json.map(_data('buan.quizzes.active.json')));
    final answer = QuizAnswerResult.fromJson(Json.map(_data('buan.quizzes._.answers.post.json')));
    for (final q in quiz.questions) {
      expect(q.options.map((o) => o.id), contains(answer.correctOptionId), reason: q.id);
    }
    expect(Referral.fromJson(Json.map(_data('buan.referral.json'))).invitees, hasLength(3));
    expect(Json.list(_data('photo-reports.types.json'), PhotoReportType.fromJson), hasLength(3));
    expect(Json.list(_data('photo-reports.mine.json'), PhotoReport.fromJson).map((r) => r.status), ReportStatus.values);
    expect(PhotoReport.fromJson(Json.map(_data('photo-reports.post.json'))).status, ReportStatus.pending);
    expect(Json.list(_data('games.json'), Game.fromJson).map((g) => g.kind), [GameKind.quiz, GameKind.whereIsIt, GameKind.memory]);
    expect(Tournament.fromJson(Json.map(_data('games.tournament.current.json'))).rank, 37);
    expect(GameScoreResult.fromJson(Json.map(_data('games._.score.post.json'))).awarded, 80);
  });

  test('MockInterceptor aday dosyaları', () {
    expect(MockInterceptor.candidates('/buan/daily-spin', 'POST'), contains('assets/mock/buan.daily-spin.post.json'));
    expect(MockInterceptor.candidates('/buan/videos/vid-x/progress', 'POST'), contains('assets/mock/buan.videos._.progress.post.json'));
    expect(MockInterceptor.candidates('/buan/quizzes/quiz-1/answers', 'POST'), contains('assets/mock/buan.quizzes._.answers.post.json'));
    expect(MockInterceptor.candidates('/games/game-hafiza/score', 'POST'), contains('assets/mock/games._.score.post.json'));
    expect(MockInterceptor.candidates('/photo-reports', 'POST'), contains('assets/mock/photo-reports.post.json'));
  });
}

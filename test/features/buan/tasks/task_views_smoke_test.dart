import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/storage/cache_store.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/core/widgets/app_icon.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/daily_spin.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/photo_report.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/quiz.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/referral.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/steps.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/watch_video.dart';
import 'package:bbb_genclik_kulubu_app/data/models/games/game.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/buan_tasks_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/games_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/invite/view/invite_view.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/photo_report/view/photo_report_view.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/quiz/view/quiz_view.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/spin/view/daily_spin_view.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/steps/view/steps_view.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/watch/view/watch_earn_view.dart';
import 'package:bbb_genclik_kulubu_app/features/games/view/games_view.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Spin extends Mock implements DailySpinRepository {}

class _Watch extends Mock implements WatchEarnRepository {}

class _Steps extends Mock implements StepsRepository {}

class _Quiz extends Mock implements QuizRepository {}

class _Ref extends Mock implements ReferralRepository {}

class _Photo extends Mock implements PhotoReportRepository {}

class _Games extends Mock implements GamesRepository {}

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  locale: const Locale('tr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

/// Görev ekranları: düzen hatası / taşma olmadan çizilir; çark akışı uçtan uca.
void main() {
  final spin = _Spin();
  const opts = [QuizOption(id: 'a', label: '12'), QuizOption(id: 'c', label: '20')];

  setUpAll(() async {
    await initializeDateFormatting('tr');
    SharedPreferences.setMockInitialValues({});
    final cache = await CacheStore.create();
    final watch = _Watch(), steps = _Steps(), quiz = _Quiz(), ref = _Ref(), photo = _Photo(), games = _Games();
    when(() => spin.status()).thenAnswer(
      (_) async => const Success(
        DailySpinStatus(
          available: true,
          slices: [
            SpinSlice(id: 'a', amount: 10),
            SpinSlice(id: 'b', amount: 50),
          ],
        ),
      ),
    );
    when(
      () => spin.spin(any()),
    ).thenAnswer((_) async => Success(SpinResult(sliceIndex: 1, amount: 50, nextSpinAt: DateTime.now().add(const Duration(hours: 5)))));
    when(watch.current).thenAnswer(
      (_) async => const Success(
        WatchVideo(
          id: 'v',
          youtubeId: 'y',
          title: 'Gençlik',
          source: 'Belediye videosu',
          durationSec: 120,
          reward: 1000,
          upNext: [UpcomingVideo(id: 'u', title: 'Spor')],
        ),
      ),
    );
    when(steps.summary).thenAnswer(
      (_) async => Success(
        StepsSummary(
          date: DateTime(2026, 10, 16),
          goal: 8000,
          reward: 750,
          steps: 6240,
          week: [StepDay(date: DateTime(2026, 10, 15), steps: 9000)],
        ),
      ),
    );
    when(quiz.active).thenAnswer(
      (_) async => const Success(
        Quiz(
          id: 'q',
          title: 'Bursa Bilgi',
          reward: 100,
          remainingThisWeek: 2,
          questions: [QuizQuestion(id: 'q1', text: 'Kaç kubbe?', options: opts)],
        ),
      ),
    );
    when(
      () => quiz.answer(
        any(),
        questionId: any(named: 'questionId'),
        optionId: any(named: 'optionId'),
        elapsedMs: any(named: 'elapsedMs'),
      ),
    ).thenAnswer((_) async => const Success(QuizAnswerResult(correctOptionId: 'c', awarded: 100)));
    when(ref.referral).thenAnswer(
      (_) async => const Success(
        Referral(
          code: 'AYSE-7K2',
          inviterReward: 2000,
          inviteeReward: 500,
          weeklyUsed: 1,
          invitees: [Invitee(id: 'i', name: 'Mert K.', initials: 'MK', status: InviteeStatus.rewarded, reward: 2000)],
        ),
      ),
    );
    when(photo.types).thenAnswer(
      (_) async => const Success([
        PhotoReportType(
          id: 'beauty',
          label: 'Güzellik',
          reward: 500,
          categories: [ReportCategory(id: 'v', label: 'Manzara')],
        ),
        PhotoReportType(
          id: 'idea',
          label: 'Fikir',
          reward: 250,
          requiresPhoto: false,
          categories: [ReportCategory(id: 'y', label: 'Gençlik')],
        ),
      ]),
    );
    when(photo.mine).thenAnswer(
      (_) async => Success([
        PhotoReport(id: 'r', title: 'Gün batımı', createdAt: DateTime(2026, 10, 12), status: ReportStatus.approved, reward: 500),
      ]),
    );
    when(games.games).thenAnswer(
      (_) async => const Success([Game(id: 'g', title: 'Hafıza Kartları', description: 'Eşleştir', kind: GameKind.memory, reward: 80)]),
    );
    when(games.tournament).thenAnswer(
      (_) async => Success(
        Tournament(
          id: 't',
          title: 'Bursa Bilgi Turnuvası',
          gameId: 'g',
          totalPrize: 5000,
          endsAt: DateTime.now().add(const Duration(days: 3)),
          rank: 37,
          participants: 1284,
        ),
      ),
    );
    sl
      ..registerSingleton<CacheStore>(cache)
      ..registerSingleton<DailySpinRepository>(spin)
      ..registerSingleton<WatchEarnRepository>(watch)
      ..registerSingleton<StepsRepository>(steps)
      ..registerSingleton<QuizRepository>(quiz)
      ..registerSingleton<ReferralRepository>(ref)
      ..registerSingleton<PhotoReportRepository>(photo)
      ..registerSingleton<GamesRepository>(games);
  });

  tearDownAll(sl.reset);

  Future<void> pumpView(WidgetTester tester, Widget view, {ThemeData? theme}) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(_app(view, theme: theme));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Günlük Şans: çevir → sonuç penceresi', (tester) async {
    await pumpView(tester, const DailySpinView());
    expect(find.text('Günlük Şans'), findsOneWidget);
    await tester.tap(find.text('Çevir'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Şansın yaver gitti!'), findsOneWidget);
    await tester.tap(find.text('Süper'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bugünkü şansını kullandın'), findsOneWidget);
    await tester.tap(find.text('Salla Kazan'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Günlük Şans koyu tema', (tester) async {
    await pumpView(tester, const DailySpinView(), theme: AppTheme.dark);
    await tester.tap(find.text('Salla Kazan'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Telefonunu salla!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('İzle Kazan', (tester) async {
    await pumpView(tester, const WatchEarnView());
    expect(find.text('İzlemeye devam et'), findsOneWidget);
    expect(find.text('SIRADAKİ VİDEOLAR'), findsOneWidget);
  });

  testWidgets('Bir Adım At', (tester) async {
    await pumpView(tester, const StepsView());
    expect(find.text('Hedefe 1.760 adım kaldı'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Cevapla Kazan: doğru cevap', (tester) async {
    await pumpView(tester, const QuizView());
    expect(find.text('Bursa Bilgi · Soru 1 / 1'), findsOneWidget);
    await tester.tap(find.text('20'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byWidgetPredicate((w) => w is AppIcon && w.semanticLabel == 'Doğru'), findsOneWidget);
    await tester.tap(find.text('Sonuçları gör'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('1 / 1 doğru'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Davet Et', (tester) async {
    await pumpView(tester, const InviteView());
    expect(find.text('AYSE-7K2'), findsOneWidget);
    expect(find.text('+2.000 kazandın'), findsOneWidget);
  });

  testWidgets('Çek Kazan + Fikir sekmesi', (tester) async {
    await pumpView(tester, const PhotoReportView());
    expect(find.text('Çek Kazan'), findsOneWidget);
    expect(find.text('+500 onaylandı'), findsOneWidget);
    await tester.tap(find.text('Fikir'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Fikrin ile Kazan'), findsOneWidget);
  });

  testWidgets('Oyunlar', (tester) async {
    await pumpView(tester, const GamesView());
    expect(find.text('Bursa Bilgi Turnuvası'), findsOneWidget);
    expect(find.text('Sıran: 37 / 1.284'), findsOneWidget);
    await tester.tap(find.text('Hafıza Kartları'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('0 hamle'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/session/session_controller.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_reward.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/market/view/reward_detail_view.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/market/view_model/reward_detail_view_model.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'buan_fixtures.dart';

class _MockSession extends Mock implements SessionController {}

void main() {
  late MockBuanRepository repo;
  late _MockSession session;
  late List<ApiResult<BuanRedeemResult>> answers;

  setUpAll(() async {
    registerFallbackValue(reward());
    await initializeDateFormatting('tr');
    Provider.debugCheckInvalidValueType = null;
  });

  setUp(() {
    repo = MockBuanRepository(balance: 12450);
    session = _MockSession();
    when(() => session.isAuthenticated).thenReturn(true);
    when(() => repo.reward('rwd-teleferik')).thenAnswer((_) async => Success(reward()));
    answers = [const Success(BuanRedeemResult(code: 'TLF-48QK'))];
    when(() => repo.redeem(any(), idempotencyKey: any(named: 'idempotencyKey'))).thenAnswer((_) async {
      final r = answers.removeAt(0);
      if (r is Success<BuanRedeemResult>) repo.balanceNotifier.value = 4450;
      return r;
    });
  });

  Future<RewardDetailViewModel> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var n = 0;
    final vm = RewardDetailViewModel(repo, 'rwd-teleferik', keyFactory: () => 'key-${++n}');
    await tester.pumpWidget(
      Provider<SessionController>.value(
        value: session,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: ChangeNotifierProvider<RewardDetailViewModel>.value(value: vm, child: const RewardDetailBody()),
        ),
      ),
    );
    await vm.load();
    await tester.pumpAndSettle();
    return vm;
  }

  testWidgets('üye: BUAN ile Al → onay sheet → Onayla → başarı ekranı', (tester) async {
    await pump(tester);
    expect(find.text('Teleferik + sucuk ekmek'), findsOneWidget);
    expect(find.text('4.450'), findsOneWidget, reason: 'takastan sonra önizlemesi');

    await tester.tap(find.text('BUAN ile Al'));
    await tester.pumpAndSettle();
    expect(find.text('Takası onayla'), findsOneWidget);
    expect(find.text('Bakiyen 12.450 → 4.450 BUAN olacak. Bu işlem geri alınamaz.'), findsOneWidget);

    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();

    verify(() => repo.redeem(any(), idempotencyKey: 'key-1')).called(1);
    expect(find.text('Takası onayla'), findsNothing);
    expect(find.text('Ödülün hazır!'), findsOneWidget);
    expect(find.text('TLF-48QK'), findsOneWidget);
    expect(find.text('Kalan bakiye: 4.450 BUAN · Kod “Fırsatlarım”da'), findsOneWidget);
  });

  testWidgets('hata sheet içinde gösterilir; tekrar deneme aynı anahtarla', (tester) async {
    answers = [const Failure(ConflictException(serverMessage: 'Stok tükendi')), const Success(BuanRedeemResult(code: 'TLF-48QK'))];
    await pump(tester);
    await tester.tap(find.text('BUAN ile Al'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();
    expect(find.text('Stok tükendi'), findsOneWidget);
    expect(find.text('Takası onayla'), findsOneWidget);

    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();
    verify(() => repo.redeem(any(), idempotencyKey: 'key-1')).called(2);
    expect(find.text('Ödülün hazır!'), findsOneWidget);
  });

  testWidgets('Vazgeç sheet’i kapatır, takas yapılmaz', (tester) async {
    await pump(tester);
    await tester.tap(find.text('BUAN ile Al'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Takası onayla'), findsNothing);
    verifyNever(() => repo.redeem(any(), idempotencyKey: any(named: 'idempotencyKey')));
  });

  testWidgets('misafir: misafir duvarı açılır, takas yapılmaz', (tester) async {
    when(() => session.isAuthenticated).thenReturn(false);
    await pump(tester);
    await tester.tap(find.text('BUAN ile Al'));
    await tester.pumpAndSettle();
    expect(find.text('Takası onayla'), findsNothing);
    verifyNever(() => repo.redeem(any(), idempotencyKey: any(named: 'idempotencyKey')));
  });

  testWidgets('bakiye yetmiyorsa buton pasif ve eksik tutarı söyler', (tester) async {
    repo.balanceNotifier.value = 5000;
    await pump(tester);
    expect(find.text('3.000 BUAN eksik'), findsOneWidget);
    await tester.tap(find.text('3.000 BUAN eksik'));
    await tester.pumpAndSettle();
    expect(find.text('Takası onayla'), findsNothing);
  });
}

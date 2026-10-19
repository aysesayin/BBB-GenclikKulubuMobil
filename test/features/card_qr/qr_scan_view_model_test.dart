import 'dart:async';

import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/card/digital_card.dart';
import 'package:bbb_genclik_kulubu_app/features/card_qr/view_model/qr_scan_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'card_mocks.dart';

void main() {
  late MockCardRepository repo;
  const result = QrCheckInResult(placeName: 'Aşık Veysel Gençlik Merkezi', buan: 300);

  setUp(() {
    repo = MockCardRepository();
    registerFallbackValue(const GeoPoint(0, 0));
  });

  test('okunan kod konumla gönderilir → başarı', () async {
    when(
      () => repo.checkIn(
        rotatingToken: 'tok',
        geo: any(named: 'geo'),
      ),
    ).thenAnswer((_) async => const Success(result));
    final vm = QrScanViewModel(repo, locate: () async => const GeoPoint(40.19, 29.06));
    await vm.onCode(' tok ');
    expect(vm.phase, ScanPhase.success);
    expect(vm.result?.buan, 300);
    final geo =
        verify(
              () => repo.checkIn(
                rotatingToken: 'tok',
                geo: captureAny(named: 'geo'),
              ),
            ).captured.single
            as GeoPoint;
    expect(geo.lat, 40.19);
  });

  test('gönderim sürerken gelen kareler yok sayılır', () async {
    final c = Completer<ApiResult<QrCheckInResult>>();
    when(
      () => repo.checkIn(
        rotatingToken: any(named: 'rotatingToken'),
        geo: any(named: 'geo'),
      ),
    ).thenAnswer((_) => c.future);
    final vm = QrScanViewModel(repo);
    final first = vm.onCode('tok');
    await Future<void>.delayed(Duration.zero);
    expect(vm.phase, ScanPhase.submitting);
    await vm.onCode('tok');
    await vm.onCode('baska');
    c.complete(const Success(result));
    await first;
    verify(
      () => repo.checkIn(
        rotatingToken: any(named: 'rotatingToken'),
        geo: any(named: 'geo'),
      ),
    ).called(1);
  });

  test('boş kod yok sayılır', () async {
    final vm = QrScanViewModel(repo);
    await vm.onCode('  ');
    await vm.onCode(null);
    expect(vm.phase, ScanPhase.scanning);
    verifyZeroInteractions(repo);
  });

  test('hata → failure; tekrar dene aynı kodla gönderir; sıfırla taramaya döner', () async {
    when(
      () => repo.checkIn(
        rotatingToken: 'tok',
        geo: any(named: 'geo'),
      ),
    ).thenAnswer((_) async => const Failure(ConflictException(serverMessage: 'Bugün zaten check-in yaptın')));
    final vm = QrScanViewModel(repo, locate: () async => throw StateError('konum yok'));
    await vm.onCode('tok');
    expect(vm.phase, ScanPhase.failure);
    expect(vm.error?.serverMessage, 'Bugün zaten check-in yaptın');

    when(
      () => repo.checkIn(
        rotatingToken: 'tok',
        geo: any(named: 'geo'),
      ),
    ).thenAnswer((_) async => const Success(result));
    await vm.retry();
    expect(vm.phase, ScanPhase.success);

    vm.reset();
    expect(vm.phase, ScanPhase.scanning);
    expect(vm.result, isNull);
  });

  test('el feneri durumu', () {
    final vm = QrScanViewModel(repo)..setTorch(true);
    expect(vm.torch, isTrue);
  });
}

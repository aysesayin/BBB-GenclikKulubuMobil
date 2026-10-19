import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/discount.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/discounts/view_model/discounts_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/view_model/picked_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

void main() {
  late MockProfileRepository repo;
  late DiscountsViewModel vm;

  const types = [
    DiscountType(id: 'ogrenci', name: 'Öğrenci', requiredDocument: 'e-Devlet öğrenci belgesi'),
    DiscountType(id: 'kardes', name: 'Kardeş', requiredDocument: 'Nüfus kayıt örneği'),
  ];
  final mine = [
    UserDiscount(id: 'dsc-1', typeId: 'ogrenci', typeName: 'Öğrenci', status: DiscountStatus.approved, validUntil: DateTime(2027, 6, 30)),
  ];
  const doc = PickedDocument(path: '/tmp/belge.jpg', name: 'belge.jpg', sizeBytes: 1024);
  const created = UserDiscount(id: 'dsc-new', typeId: 'kardes', typeName: 'Kardeş');

  setUp(() {
    repo = MockProfileRepository();
    when(() => repo.discountTypes()).thenAnswer((_) async => const Success(types));
    when(() => repo.discounts()).thenAnswer((_) async => Success(mine));
    vm = DiscountsViewModel(repo, clock: () => DateTime(2026, 10, 16));
  });

  DiscountsData data() => (vm.state as ViewSuccess<DiscountsData>).data;

  test('türler ve tanımlı indirimler yüklenir', () async {
    await vm.load();
    expect(data().types, hasLength(2));
    expect(data().mine.single.id, 'dsc-1');
  });

  test('tür / belge olmadan gönderilmez', () async {
    await vm.load();
    expect(await vm.submit(), isFalse);
    expect(vm.issue, DiscountFormIssue.noType);
    vm.selectType('kardes');
    expect(vm.selectedType?.requiredDocument, 'Nüfus kayıt örneği');
    expect(await vm.submit(), isFalse);
    expect(vm.issue, DiscountFormIssue.noDocument);
  });

  test('5 MB üstü belge reddedilir', () async {
    vm.setDocument(const PickedDocument(path: '/b', name: 'b.jpg', sizeBytes: PickedDocument.maxBytes + 1));
    expect(vm.document, isNull);
    expect(vm.issue, DiscountFormIssue.tooLarge);
  });

  test('oluştur → belge yükle → listenin başına eklenir, form sıfırlanır', () async {
    when(() => repo.createDiscount(any(), idempotencyKey: any(named: 'idempotencyKey'))).thenAnswer((_) async => const Success(created));
    when(
      () => repo.uploadDiscountDocument(
        any(),
        path: any(named: 'path'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => const Success(null));
    await vm.load();
    vm
      ..selectType('kardes')
      ..setDocument(doc);
    expect(await vm.submit(), isTrue);
    verify(() => repo.uploadDiscountDocument('dsc-new', path: '/tmp/belge.jpg', fileName: 'belge.jpg')).called(1);
    expect(data().mine.first.id, 'dsc-new');
    expect(vm.selectedTypeId, isNull);
    expect(vm.document, isNull);
  });

  test('yükleme başarısızsa tekrar denemede kayıt yeniden oluşturulmaz', () async {
    when(() => repo.createDiscount(any(), idempotencyKey: any(named: 'idempotencyKey'))).thenAnswer((_) async => const Success(created));
    when(
      () => repo.uploadDiscountDocument(
        any(),
        path: any(named: 'path'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => const Failure(NetworkException()));
    await vm.load();
    vm
      ..selectType('kardes')
      ..setDocument(doc);
    expect(await vm.submit(), isFalse);
    expect(vm.error, isA<NetworkException>());

    when(
      () => repo.uploadDiscountDocument(
        any(),
        path: any(named: 'path'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => const Success(null));
    expect(await vm.submit(), isTrue);
    verify(() => repo.createDiscount(any(), idempotencyKey: any(named: 'idempotencyKey'))).called(1);
  });

  test('yenile: reddedilen indirimin türü seçilir', () async {
    await vm.load();
    vm.renew(const UserDiscount(id: 'x', typeId: 'kardes', status: DiscountStatus.rejected));
    expect(vm.selectedTypeId, 'kardes');
  });

  test('effectiveStatus: 15 gün içinde biten onaylı indirim "süresi doluyor"', () {
    final today = DateTime(2026, 10, 16);
    expect(
      UserDiscount(id: 'a', typeId: 't', status: DiscountStatus.approved, validUntil: DateTime(2026, 10, 30)).effectiveStatus(today),
      DiscountStatus.expiring,
    );
    expect(
      UserDiscount(id: 'a', typeId: 't', status: DiscountStatus.approved, validUntil: DateTime(2027, 6, 30)).effectiveStatus(today),
      DiscountStatus.approved,
    );
    expect(
      UserDiscount(id: 'a', typeId: 't', status: DiscountStatus.approved, validUntil: DateTime(2026, 10, 1)).effectiveStatus(today),
      DiscountStatus.expired,
    );
  });
}

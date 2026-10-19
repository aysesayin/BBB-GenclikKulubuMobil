import 'dart:typed_data';

import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/photo_report.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/buan_tasks_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/photo_report/view_model/photo_report_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements PhotoReportRepository {}

const _types = [
  PhotoReportType(
    id: 'beauty',
    label: 'Güzellik',
    reward: 500,
    categories: [
      ReportCategory(id: 'view', label: 'Manzara'),
      ReportCategory(id: 'nature', label: 'Doğa'),
    ],
  ),
  PhotoReportType(
    id: 'idea',
    label: 'Fikir',
    reward: 250,
    requiresPhoto: false,
    categories: [ReportCategory(id: 'youth', label: 'Gençlik')],
  ),
];

void main() {
  late _Repo repo;
  final created = PhotoReport(id: 'r-new', title: 'Yeni', createdAt: DateTime(2026, 10, 16));
  final old = PhotoReport(id: 'r-1', title: 'Eski', createdAt: DateTime(2026, 10, 1), status: ReportStatus.approved);

  setUpAll(() => registerFallbackValue(const PhotoReportDraft(typeId: '', categoryId: '', note: '')));

  setUp(() {
    repo = _Repo();
    when(() => repo.types()).thenAnswer((_) async => const Success(_types));
    when(() => repo.mine()).thenAnswer((_) async => Success([old]));
    when(() => repo.submit(any())).thenAnswer((_) async => Success(created));
  });

  PhotoReportViewModel make({({double lat, double lng})? loc = (lat: 40.18, lng: 29.06)}) =>
      PhotoReportViewModel(repo, locate: () async => loc);

  test('yükleme: türler, ilk kategori, gönderilerim', () async {
    final vm = make();
    await vm.load();
    expect(vm.type!.id, 'beauty');
    expect(vm.categoryId, 'view');
    expect(vm.mine, [old]);
    expect(vm.canSubmit, isFalse, reason: 'fotoğraf zorunlu');
  });

  test('fotoğraf + konum ile multipart taslak gönderilir', () async {
    final vm = make();
    await vm.load();
    vm.selectCategory('nature');
    vm.setNote('  güzel manzara ');
    await vm.setPhoto(Uint8List.fromList([1, 2, 3]), 'a.jpg');
    expect(vm.locationStatus, LocationStatus.added);
    expect(vm.canSubmit, isTrue);

    final r = await vm.submit();
    expect(r, created);
    final draft = verify(() => repo.submit(captureAny())).captured.single as PhotoReportDraft;
    expect(draft.typeId, 'beauty');
    expect(draft.categoryId, 'nature');
    expect(draft.note, 'güzel manzara');
    expect(draft.photo, [1, 2, 3]);
    expect(draft.photoName, 'a.jpg');
    expect(draft.latitude, 40.18);
    expect(vm.mine.first, created);
    expect(vm.photo, isNull);
    expect(vm.note, isEmpty);
  });

  test('konum izni yoksa denied, gönderim yine mümkün', () async {
    final vm = make(loc: null);
    await vm.load();
    await vm.setPhoto(Uint8List(1), 'b.jpg');
    expect(vm.locationStatus, LocationStatus.denied);
    expect(vm.canSubmit, isTrue);
  });

  test('fikir türü: fotoğrafsız, en az 10 karakter not', () async {
    final vm = make();
    await vm.load();
    vm.selectType(1);
    expect(vm.needsPhoto, isFalse);
    expect(vm.categoryId, 'youth');
    vm.setNote('kısa');
    expect(vm.canSubmit, isFalse);
    vm.setNote('Gece açık çalışma salonu olsun');
    expect(vm.canSubmit, isTrue);
    await vm.submit();
    final draft = verify(() => repo.submit(captureAny())).captured.single as PhotoReportDraft;
    expect(draft.photo, isNull);
    expect(draft.typeId, 'idea');
  });

  test('hata: liste değişmez, hata yayınlanır', () async {
    when(() => repo.submit(any())).thenAnswer((_) async => const Failure(NetworkException()));
    final vm = make();
    await vm.load();
    await vm.setPhoto(Uint8List(1), 'c.jpg');
    expect(await vm.submit(), isNull);
    expect(vm.error, isA<NetworkException>());
    expect(vm.mine, [old]);
    expect(vm.photo, isNotNull, reason: 'kullanıcı yeniden deneyebilsin');
  });
}

import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/utils/validators.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/child_profile.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/children/view_model/children_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

void main() {
  late MockProfileRepository repo;
  late ChildrenViewModel vm;

  const deniz = ChildProfile(id: 'chd-deniz', displayName: 'Deniz S. E.', initial: 'D', age: 9);
  const can = ChildProfile(id: 'chd-can', displayName: 'Can S. E.', initial: 'C', age: 7);

  setUpAll(registerProfileFallbacks);

  setUp(() {
    repo = MockProfileRepository();
    when(() => repo.children()).thenAnswer((_) async => const Success([deniz]));
    vm = ChildrenViewModel(repo, clock: () => DateTime(2026, 10, 16));
  });

  List<ChildProfile> kids() => (vm.state as ViewSuccess<List<ChildProfile>>).data;

  void stubAdd(ApiResult<ChildProfile> r) => when(
    () => repo.addChild(
      tckn: any(named: 'tckn'),
      birthDate: any(named: 'birthDate'),
    ),
  ).thenAnswer((_) async => r);

  test('tarih ayrıştırma', () {
    expect(ChildrenViewModel.parseDate('02.05.2017'), DateTime(2017, 5, 2));
    expect(ChildrenViewModel.parseDate('31.02.2017'), isNull);
    expect(ChildrenViewModel.parseDate('2017-05-02'), isNull);
  });

  test('geçersiz TCKN ve tarih istemcide yakalanır', () async {
    await vm.load();
    expect(await vm.add(tckn: '123 456 780 12', birthDate: '99.99.2000'), isNull);
    expect(vm.tcknIssue, ValidationIssue.tcknInvalid);
    expect(vm.dateInvalid, isTrue);
    verifyNever(
      () => repo.addChild(
        tckn: any(named: 'tckn'),
        birthDate: any(named: 'birthDate'),
      ),
    );
  });

  test('18 yaşını doldurmuş kişi istemcide reddedilir', () async {
    await vm.load();
    expect(await vm.add(tckn: validTckn, birthDate: '02.05.2007'), isNull);
    expect(vm.issue, ChildFormIssue.overAge);
  });

  test('gelecek tarih reddedilir', () async {
    await vm.load();
    await vm.add(tckn: validTckn, birthDate: '01.01.2030');
    expect(vm.dateFuture, isTrue);
  });

  test('başarılı ekleme: rakamlar gönderilir, liste güncellenir', () async {
    stubAdd(const Success(can));
    await vm.load();
    final added = await vm.add(tckn: '100 000 001 46', birthDate: '10.03.2019');
    expect(added, can);
    verify(() => repo.addChild(tckn: validTckn, birthDate: DateTime(2019, 3, 10))).called(1);
    expect(kids().map((c) => c.id), ['chd-deniz', 'chd-can']);
    expect(vm.submitting, isFalse);
  });

  test('sunucu yaş reddi (403) → overAge, MERNİS uyuşmazlığı (422) → mernisFailed', () async {
    await vm.load();
    stubAdd(const Failure(ForbiddenException()));
    await vm.add(tckn: validTckn, birthDate: '10.03.2019');
    expect(vm.issue, ChildFormIssue.overAge);
    stubAdd(const Failure(ValidationException()));
    await vm.add(tckn: validTckn, birthDate: '10.03.2019');
    expect(vm.issue, ChildFormIssue.mernisFailed);
    stubAdd(const Failure(ConflictException()));
    await vm.add(tckn: validTckn, birthDate: '10.03.2019');
    expect(vm.issue, ChildFormIssue.alreadyAdded);
  });

  test('ağ hatası genel hata olarak saklanır; clearIssues temizler', () async {
    await vm.load();
    stubAdd(const Failure(NetworkException()));
    await vm.add(tckn: validTckn, birthDate: '10.03.2019');
    expect(vm.issue, isNull);
    expect(vm.error, isA<NetworkException>());
    vm.clearIssues();
    expect(vm.error, isNull);
  });
}

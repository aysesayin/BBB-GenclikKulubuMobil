import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/delete_request.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/support.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/support/view_model/support_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/view_model/picked_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

void main() {
  late MockSupportRepository support;
  late MockProfileRepository profile;
  late SupportViewModel vm;

  final old = SupportTicket(id: 't1', number: '24817', subject: 'Dolap', createdAt: DateTime(2026, 10, 12), status: TicketStatus.answered);
  final fresh = SupportTicket(id: 't2', number: '25010', subject: 'Yeni', type: SupportType.sikayet, createdAt: DateTime(2026, 10, 16));
  const faq = [FaqItem(id: 'f1', question: 'S?', answer: 'C.'), FaqItem(id: 'f2', question: 'S2?', answer: 'C2.')];

  setUpAll(registerProfileFallbacks);

  setUp(() {
    support = MockSupportRepository();
    profile = MockProfileRepository();
    when(() => support.tickets()).thenAnswer((_) async => Success([old]));
    when(() => support.faq()).thenAnswer((_) async => const Success(faq));
    vm = SupportViewModel(support, profile);
  });

  SupportData data() => (vm.state as ViewSuccess<SupportData>).data;

  void stubSubmit(ApiResult<SupportTicket> r) => when(
    () => support.submit(
      type: any(named: 'type'),
      topic: any(named: 'topic'),
      message: any(named: 'message'),
      attachmentPath: any(named: 'attachmentPath'),
      attachmentName: any(named: 'attachmentName'),
    ),
  ).thenAnswer((_) async => r);

  test('talepler + SSS yüklenir; SSS hatası ekranı düşürmez', () async {
    await vm.load();
    expect(data().faq, hasLength(2));
    when(() => support.faq()).thenAnswer((_) async => const Failure(ServerException()));
    await vm.load();
    expect(data().faq, isEmpty);
  });

  test('kısa mesaj gönderilmez', () async {
    await vm.load();
    expect(await vm.submit('kısa'), isNull);
    expect(vm.issue, SupportFormIssue.messageShort);
  });

  test('tür, konu ve ek gönderilir; yeni talep başa eklenir, ek temizlenir', () async {
    stubSubmit(Success(fresh));
    await vm.load();
    vm
      ..setType(SupportType.sikayet)
      ..setTopic(SupportTopic.buan)
      ..setAttachment(const PickedDocument(path: '/e.jpg', name: 'e.jpg', sizeBytes: 10));
    final t = await vm.submit('  Havuz dolabı kırık, 12 Ekim akşamı.  ');
    expect(t, fresh);
    verify(
      () => support.submit(
        type: SupportType.sikayet,
        topic: 'buan',
        message: 'Havuz dolabı kırık, 12 Ekim akşamı.',
        attachmentPath: '/e.jpg',
        attachmentName: 'e.jpg',
      ),
    ).called(1);
    expect(data().tickets.map((e) => e.id), ['t2', 't1']);
    expect(vm.attachment, isNull);
  });

  test('gönderim hatası saklanır', () async {
    stubSubmit(const Failure(NetworkException()));
    await vm.load();
    expect(await vm.submit('Bu yeterince uzun bir mesaj.'), isNull);
    expect(vm.error, isA<NetworkException>());
    expect(vm.sending, isFalse);
  });

  test('SSS akordeonu tek satır açar', () {
    expect(vm.openFaq, 0);
    vm.toggleFaq(1);
    expect(vm.openFaq, 1);
    vm.toggleFaq(1);
    expect(vm.openFaq, -1);
  });

  test('büyük ek reddedilir', () {
    vm.setAttachment(const PickedDocument(path: '/x', name: 'x', sizeBytes: PickedDocument.maxBytes + 1));
    expect(vm.attachment, isNull);
    expect(vm.issue, SupportFormIssue.tooLarge);
  });

  test('KVKK silme talebi', () async {
    when(() => profile.requestDeletion()).thenAnswer((_) async => Success(demoReceipt));
    expect(await vm.requestDeletion(), isA<Success<DeleteRequestReceipt>>());
    verify(() => profile.requestDeletion()).called(1);
  });
}

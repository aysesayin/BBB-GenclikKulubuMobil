import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/stories/story.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/story_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/stories/view_model/story_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStoryRepository extends Mock implements StoryRepository {}

final _story = Story(
  id: 'sto-genclik-kampi',
  author: 'Gençlik Kulübü',
  publishedAt: DateTime(2026, 10, 16, 8),
  slides: const [
    StorySlide(id: 's1', title: 'Bir'),
    StorySlide(id: 's2', title: 'İki'),
    StorySlide(id: 's3', title: 'Üç'),
  ],
);

void main() {
  late _MockStoryRepository repo;

  setUp(() {
    repo = _MockStoryRepository();
    when(() => repo.detail(any())).thenAnswer((_) async => Success(_story));
    when(() => repo.markSeen(any())).thenAnswer((_) async => const Success<void>(null));
  });

  test('yükleme sonrası bir kez "görüldü" gönderilir', () async {
    final vm = StoryViewModel(repo, 'sto-genclik-kampi');
    await vm.load();
    await vm.load();
    expect(vm.count, 3);
    expect(vm.current?.id, 's1');
    verify(() => repo.markSeen('sto-genclik-kampi')).called(1);
  });

  test('ileri / geri gezinme sınırları ve bitiş', () async {
    final vm = StoryViewModel(repo, 'x');
    await vm.load();
    final g0 = vm.generation;
    vm.previous();
    expect(vm.index, 0, reason: 'ilk segmentte geri = baştan başlat');
    expect(vm.generation, g0 + 1);

    vm.next();
    vm.next();
    expect(vm.index, 2);
    expect(vm.finished, isFalse);
    vm.previous();
    expect(vm.index, 1);
    vm.next();
    vm.next();
    expect(vm.finished, isTrue);
    expect(vm.index, 2);

    final g = vm.generation;
    vm.next();
    vm.previous();
    expect(vm.generation, g, reason: 'bittikten sonra gezinme yok');
  });

  test('duraklatma', () async {
    final vm = StoryViewModel(repo, 'x');
    await vm.load();
    vm.setPaused(value: true);
    expect(vm.paused, isTrue);
    vm.setPaused(value: false);
    expect(vm.paused, isFalse);
  });

  test('segmentsiz hikâye → ViewEmpty, görüldü gönderilmez', () async {
    when(() => repo.detail(any())).thenAnswer((_) async => Success(_story.copyWith(slides: const [])));
    final vm = StoryViewModel(repo, 'x');
    await vm.load();
    expect(vm.state, isA<ViewEmpty<Story>>());
    vm.next();
    expect(vm.finished, isFalse);
    verifyNever(() => repo.markSeen(any()));
  });

  test('hata → ViewError, görüldü gönderilmez', () async {
    when(() => repo.detail(any())).thenAnswer((_) async => const Failure(NotFoundException()));
    final vm = StoryViewModel(repo, 'x');
    await vm.load();
    expect(vm.state, isA<ViewError<Story>>());
    verifyNever(() => repo.markSeen(any()));
  });

  test('yaş hesabı', () async {
    final vm = StoryViewModel(repo, 'x');
    expect(vm.ageAt(DateTime(2026)), Duration.zero);
    await vm.load();
    expect(vm.ageAt(DateTime(2026, 10, 16, 10)), const Duration(hours: 2));
    expect(vm.ageAt(DateTime(2026, 10, 16, 7)), Duration.zero);
  });

  test('mock stories._.json modele çözülür', () {
    final json = jsonDecode(File('assets/mock/stories._.json').readAsStringSync()) as Map<String, dynamic>;
    final story = Story.fromJson(json['data'] as Map<String, dynamic>);
    expect(story.slides.length, 3);
    expect(story.slides.map((s) => s.theme), ['teal', 'buan', 'fresh']);
  });
}

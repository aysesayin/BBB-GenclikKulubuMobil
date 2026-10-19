import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/stories/story.dart';
import '../../../data/repositories/story_repository.dart';

/// B4 · Hikâye görüntüleyici: segment gezinmesi + görüldü bildirimi.
/// Zamanlama (6 sn/segment, basılı tut = duraklat) görünümdeki AnimationController'dadır;
/// VM yalnız konum ve durum tutar.
class StoryViewModel extends LoadableViewModel<Story> {
  StoryViewModel(this._repo, this.storyId);

  final StoryRepository _repo;
  final String storyId;

  /// Segment süresi (tasarım notu: 6 sn).
  static const segmentDuration = Duration(seconds: 6);

  int _index = 0;
  int get index => _index;

  /// Her gezinmede artar; görünüm ilerleme animasyonunu buna göre sıfırlar
  /// (ilk segmentte "geri" = segmenti baştan başlat).
  int _generation = 0;
  int get generation => _generation;

  bool _paused = false;
  bool get paused => _paused;

  bool _finished = false;

  /// Son segment bitti / ileri geçildi → görünüm kapanır.
  // TODO(varsayım): Son segmentten sonra sıradaki hikâyeye geçilmez, görüntüleyici kapanır.
  bool get finished => _finished;

  bool _seenSent = false;

  @override
  Future<ApiResult<Story>> fetch() => _repo.detail(storyId);

  @override
  bool isEmpty(Story data) => data.slides.isEmpty;

  @override
  Future<void> load() async {
    await super.load();
    if (state is ViewSuccess<Story> && !_seenSent) {
      _seenSent = true;
      unawaited(_repo.markSeen(storyId));
    }
  }

  List<StorySlide> get slides => state.dataOrNull?.slides ?? const [];
  int get count => slides.length;
  StorySlide? get current => _index < count ? slides[_index] : null;

  void next() {
    if (_finished || count == 0) return;
    if (_index < count - 1) {
      _index++;
    } else {
      _finished = true;
    }
    _generation++;
    notify();
  }

  void previous() {
    if (_finished) return;
    if (_index > 0) _index--;
    _generation++;
    notify();
  }

  void setPaused({required bool value}) {
    if (_paused == value) return;
    _paused = value;
    notify();
  }

  /// "2 sa" gibi yaş etiketi için.
  Duration ageAt(DateTime now) {
    final published = state.dataOrNull?.publishedAt;
    if (published == null) return Duration.zero;
    final d = now.difference(published);
    return d.isNegative ? Duration.zero : d;
  }
}

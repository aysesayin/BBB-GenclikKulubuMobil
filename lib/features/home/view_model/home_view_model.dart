import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/home/home_feed.dart';
import '../../../data/repositories/home_repository.dart';

/// Günün saatine göre selam.
enum HomeGreeting { morning, day, evening, night }

/// Keşfet blokları — sırayı panel (`blocks`) belirler.
enum HomeBlock { stories, tasks, banners, shortcuts, deals, events, nearby, league }

/// B1 · Keşfet. Tüm bloklar tek `GET /home` çağrısından gelir.
class HomeViewModel extends LoadableViewModel<HomeFeed> {
  HomeViewModel(this._repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final HomeRepository _repo;
  final DateTime Function() _clock;

  /// Panel sıra göndermezse kullanılan varsayılan (tasarımdaki sıra).
  static const defaultOrder = HomeBlock.values;

  ViewError<HomeFeed>? _retryingFrom;

  /// Önbelleksiz hata ekranından "Tekrar dene" sürerken o hata korunur
  /// (skeleton yerine hata görünümü + "Deneniyor…" butonu, tasarım S3).
  ViewError<HomeFeed>? get retryingFrom => _retryingFrom;

  @override
  Future<ApiResult<HomeFeed>> fetch() => _repo.fetchHome();

  @override
  Future<void> load() async {
    final s = state;
    _retryingFrom = s is ViewError<HomeFeed> && s.cached == null ? s : null;
    try {
      await super.load();
    } finally {
      _retryingFrom = null;
    }
  }

  HomeGreeting get greeting => greetingFor(_clock().hour);

  /// 05–12 günaydın · 12–18 iyi günler · 18–22 iyi akşamlar · 22–05 iyi geceler.
  // TODO(varsayım): Selam saat aralıkları tasarımda tanımlı değil; yukarıdaki dilimler kullanıldı.
  static HomeGreeting greetingFor(int hour) => switch (hour) {
    >= 5 && < 12 => HomeGreeting.morning,
    >= 12 && < 18 => HomeGreeting.day,
    >= 18 && < 22 => HomeGreeting.evening,
    _ => HomeGreeting.night,
  };

  /// Panelin sırası; bilinmeyen/yinelenen anahtarlar atılır, verisi boş bloklar gizlenir.
  static List<HomeBlock> blocksOf(HomeFeed f) {
    final byName = {for (final b in HomeBlock.values) b.name: b};
    final ordered = f.blocks.isEmpty ? defaultOrder : f.blocks.map((k) => byName[k]).whereType<HomeBlock>().toSet().toList();
    return ordered.where((b) => _hasData(f, b)).toList();
  }

  static bool _hasData(HomeFeed f, HomeBlock b) => switch (b) {
    HomeBlock.stories => f.stories.isNotEmpty,
    HomeBlock.tasks => f.tasks.isNotEmpty,
    HomeBlock.banners => f.banners.isNotEmpty,
    HomeBlock.shortcuts => f.shortcuts.isNotEmpty,
    HomeBlock.deals => f.deals.isNotEmpty,
    HomeBlock.events => f.events.isNotEmpty,
    HomeBlock.nearby => f.nearby != null,
    HomeBlock.league => f.league != null,
  };

  /// Avatar baş harfleri: "Ayşe Su" → "AS" (Türkçe büyük harf).
  static String initialsOf(HomeUser u) {
    String first(String s) => s.trim().isEmpty ? '' : String.fromCharCode(s.trim().runes.first);
    return trUpper(first(u.firstName) + first(u.lastName));
  }

  /// Lig kalan süresi (gün, saat).
  static (int days, int hours) remaining(int secondsLeft) {
    final s = secondsLeft < 0 ? 0 : secondsLeft;
    return (s ~/ 86400, (s % 86400) ~/ 3600);
  }
}

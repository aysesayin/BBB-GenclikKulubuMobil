import '../../../core/widgets/app_icons.dart';
import '../../../data/models/games/game.dart';

/// Oyunlara özgü ikon yolları (24×24).
abstract final class GameIcons {
  static const memory = 'M3 4h8v10H3zM13 10h8v10h-8zM7 9h.01M17 15h.01';
  static const trophyArt = 'M90 60h60v30a30 30 0 0 1-60 0zM120 120v26M100 150h40';

  /// Hafıza kartı sembolleri: koza, kılıç-kalkan, Karagöz, kubbe, teleferik, kestane.
  // TODO(varsayım): Sembol çizimleri yer tutucu; illüstratör setiyle değişecek.
  static const symbols = [
    'M12 3c4 0 6 4 6 9s-2 9-6 9-6-4-6-9 2-9 6-9zM7 9h10M6.5 13h11M7 17h10',
    'M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6zM12 7v10M9 10h6',
    'M4 5c5-2 11-2 16 0v6a8 8 0 0 1-16 0zM9 10h.01M15 10h.01M9 15c2 1.5 4 1.5 6 0',
    'M3 21h18M5 21v-6a7 7 0 0 1 14 0v6M12 8V4M10 5h4',
    'M2 4l20 4M12 6v4M6 10h12l-1 9H7zM9 13h6',
    'M12 5c4.5 0 8 3 8 7.5S16.5 20 12 20s-8-3-8-7.5S7.5 5 12 5zM12 5c1-1.5 2.5-2 4-2M9 16h6',
  ];

  static String of(GameKind kind) => switch (kind) {
    GameKind.quiz => AppIcons.question,
    GameKind.whereIsIt => AppIcons.pin,
    GameKind.memory => memory,
    GameKind.other => AppIcons.game,
  };
}

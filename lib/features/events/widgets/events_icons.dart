import '../../../core/widgets/app_icons.dart';

/// Etkinlik ekranlarına özgü ikon yolları (tasarım G1–G2'den birebir).
abstract final class EventIcons {
  static const briefcase = 'M3 7h18v13H3zM8 7V4h8v3M3 13h18';
  static const chip = 'M4 5h16v11H4zM2 20h20M9 16v4M15 16v4M9 9h.01M15 9h.01';
  static const share = 'M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8M16 6l-4-4-4 4M12 2v13';
  static const calendarPlus = 'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zM4 10h16M8 2v4M16 2v4M12 13v5M9.5 15.5h5';
  static const age = 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 3a4 4 0 1 0 0 8 4 4 0 1 0 0-8z';
  static const chevronLeft = 'M15 18l-6-6 6-6';
  static const alert = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM12 8v5M12 16h.01';
  static const ticket = 'M3 8a2 2 0 0 0 2-2h14a2 2 0 0 0 2 2v2a2 2 0 0 0 0 4v2a2 2 0 0 0-2 2H5a2 2 0 0 0-2-2v-2a2 2 0 0 0 0-4zM13 6v12';

  /// API `icon` anahtarı → ikon yolu.
  static String forKey(String key) => switch (key) {
        'mountain' => AppIcons.mountain,
        'tent' => AppIcons.tent,
        'briefcase' => briefcase,
        'chip' => chip,
        'music' => AppIcons.music,
        'compass' => AppIcons.compass,
        'bus' => AppIcons.bus,
        'sparkle' => AppIcons.sparkle,
        'book' => AppIcons.book,
        'game' => AppIcons.game,
        'ball' => AppIcons.ball,
        _ => AppIcons.calendar,
      };
}

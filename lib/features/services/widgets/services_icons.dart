import '../../../core/widgets/app_icons.dart';

/// Hizmetler özelliğine özgü ikon yolları (24×24, tasarım dosyalarından birebir).
abstract final class SvcIcons {
  static const wave =
      'M2 18c2 0 2-1.5 4-1.5S8 18 10 18s2-1.5 4-1.5 2 1.5 4 1.5 2-1.5 4-1.5M2 13c2 0 2-1.5 4-1.5S8 13 10 13s2-1.5 4-1.5 2 1.5 4 1.5 2-1.5 4-1.5';
  static const users = 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 3a4 4 0 1 0 0 8 4 4 0 1 0 0-8z';
  static const alert = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM12 8v5M12 16h.01';
  static const chevronLeft = 'M15 18l-6-6 6-6';
  static const ticket = 'M2 9a3 3 0 0 0 0 6v3a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-3a3 3 0 0 0 0-6V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2zM13 5v2M13 17v2M13 11v2';
  static const wrench =
      'M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.8-3.8a6 6 0 0 1-7.9 7.9l-6.9 6.9a2.1 2.1 0 0 1-3-3l6.9-6.9a6 6 0 0 1 7.9-7.9z';

  // Spor branşları
  static const swim = 'M2 18c2 0 2-1.5 4-1.5S8 18 10 18s2-1.5 4-1.5 2 1.5 4 1.5 2-1.5 4-1.5M8 9a2 2 0 1 0 0-.01M5 14l4-4 4 3 4-2';
  static const fighter = 'M13 4a2 2 0 1 0 0-.01M7 21l3-6 3 2v5M16 9l-3-1-4 4 4 2M6 12l3-4M17 9l4 2';
  static const karate = 'M13 4a2 2 0 1 0 0-.01M7 21l3-6 3 2v5M16 9l-3-1-4 4 4 2M6 12l3-4';
  static const basketball = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM2 12h20M12 2v20M5 5c3 3 3 11 0 14M19 5c-3 3-3 11 0 14';
  static const tableTennis = 'M14 4a6 6 0 1 1-6 10l-4 4M18 18h.01';
  static const gymnastics = 'M12 4a2 2 0 1 0 0-.01M4 8l8 2 8-2M12 10v5l-4 6M12 15l4 6';
  static const chess = 'M8 21h8M9 17h6l1 4H8zM10 17V9M14 17V9M9 9h6M12 3v3M10.5 4.5h3';
  static const wrestling = 'M8 5a2 2 0 1 0 0-.01M16 5a2 2 0 1 0 0-.01M6 21l2-8 4 2 4-2 2 8M8 13 6 9M16 13l2-4';
  static const judo = 'M12 4a2 2 0 1 0 0-.01M6 21l3-8h6l3 8M9 13 7 8h10l-2 5M10 10h4';
  static const archery = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM12 6a6 6 0 1 0 0 12 6 6 0 1 0 0-12zM12 10a2 2 0 1 0 0 4 2 2 0 1 0 0-4zM12 12l9-9';

  /// API'deki ikon anahtarını yola çevirir (bilinmeyen → top).
  static String of(String key) => switch (key) {
        'wave' || 'pool' => wave,
        'users' => users,
        'cap' || 'course' => AppIcons.cap,
        'mountain' => AppIcons.mountain,
        'tennis' || 'kort-tenisi' => AppIcons.tennis,
        'yuzme' => swim,
        'taekwondo' => fighter,
        'karate' => karate,
        'basketbol' => basketball,
        'masa-tenisi' => tableTennis,
        'jimnastik' => gymnastics,
        'satranc' => chess,
        'gures' => wrestling,
        'judo' => judo,
        'okculuk' => archery,
        _ => AppIcons.ball,
      };
}

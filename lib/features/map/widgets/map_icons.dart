import '../../../core/widgets/app_icons.dart';

/// Harita ve yer ekranlarına özgü ikon yolları (tasarım G3–G4'ten birebir).
abstract final class MapIcons {
  static const theatre = 'M2 4h10v6a5 5 0 0 1-10 0zM12 8h10v6a5 5 0 0 1-10 0';
  static const youth = 'M3 21h18M5 21V8l7-5 7 5v13M9 21v-6h6v6';
  static const sport = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM2 12h20M12 2a15 15 0 0 1 0 20';
  static const museum = 'M3 21h18M5 21V10M19 21V10M9 21v-7M15 21v-7M2 10l10-7 10 7z';
  static const calendar = 'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zM4 10h16';
  static const tag =
      'M12.6 2.6A2 2 0 0 0 11.2 2H4a2 2 0 0 0-2 2v7.2a2 2 0 0 0 .6 1.4l8.7 8.7a2.4 2.4 0 0 0 3.4 0l6.6-6.6a2.4 2.4 0 0 0 0-3.4z';
  static const gallery = 'M3 5h18v14H3zM3 16l5-5 4 4 3-3 6 6M15 9h.01';
  static const navigate = 'M3 11l19-9-9 19-2-8z';
  static const qr = 'M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h3v3h-3zM21 21h-4v-4';

  /// API `icon` anahtarı → yol.
  static String forKey(String key) => switch (key) {
        'theatre' => theatre,
        'youth' => youth,
        'sport' => sport,
        'museum' => museum,
        'calendar' => calendar,
        'tag' => tag,
        'gallery' => gallery,
        _ => AppIcons.pinSimple,
      };
}

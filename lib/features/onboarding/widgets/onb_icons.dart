import '../../../core/widgets/app_icons.dart';

/// Giriş akışına özgü ikon yolları (24×24, tasarım dosyalarından birebir).
abstract final class OnbIcons {
  static const arrowRight = 'M5 12h14M12 5l7 7-7 7';
  static const replay = 'M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5';
  static const coinTriangle = 'M7.5 5l12 7-12 7z';
  static const sms = 'M21 11.5a8.4 8.4 0 0 1-12.4 7.4L3 21l2-5.4A8.4 8.4 0 1 1 21 11.5z';
  static const faceId =
      'M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2M8 10v1M16 10v1M12 10v3h-1M9 16c1.5 1 4.5 1 6 0';
  static const eye = 'M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12zM12 9a3 3 0 1 0 0 6 3 3 0 1 0 0-6z';
  static const eyeOff =
      'M3 3l18 18M10.6 10.6a2 2 0 0 0 2.8 2.8M9.9 5.1A10 10 0 0 1 12 5c6.4 0 10 7 10 7a17 17 0 0 1-3.2 4M6.6 6.6C3.9 8.4 2 12 2 12s3.6 7 10 7a9.7 9.7 0 0 0 5.4-1.6';

  // Hikâye pinleri
  static const pinTag =
      'M12.6 2.6A2 2 0 0 0 11.2 2H4a2 2 0 0 0-2 2v7.2a2 2 0 0 0 .6 1.4l8.7 8.7a2.4 2.4 0 0 0 3.4 0l6.6-6.6a2.4 2.4 0 0 0 0-3.4z';
  static const pinBuilding = 'M3 21h18M5 21V8l7-5 7 5v13M9 21v-6h6v6';
  static const pinCamp = 'M3 20 12 4l9 16zM12 4v16';

  // Kayıt rotası durakları: Tophane → Ulu Cami → Kozahan → Teleferik → Zirve
  static const stops = [
    'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM12 6v6l4 2',
    'M4 20V12a8 8 0 0 1 16 0v8M2 20h20',
    'M3 21h18M5 21V9l7-5 7 5v12',
    'M3 6l18-3M12 4.5V9M8 9h8v7H8z',
    'M8 3l4 8 5-5 5 15H2z',
  ];

  /// `/interests` yanıtındaki ikon anahtarı → yol.
  static String interest(String key) => switch (key) {
        'ball' => AppIcons.ball,
        'music' => AppIcons.music,
        'tech' => 'M4 5h16v11H4zM2 20h20M9 16v4M15 16v4',
        'tent' => 'M3 20 12 4l9 16zM12 4v16M8 20l4-6 4 6',
        'art' =>
          'M12 2a10 10 0 0 0 0 20c1.1 0 2-.9 2-2 0-.5-.2-1-.5-1.3-.3-.4-.5-.8-.5-1.3 0-1.1.9-2 2-2h2.4A5.5 5.5 0 0 0 22 10c0-4.4-4.5-8-10-8z',
        'career' => 'M3 7h18v13H3zM8 7V4h8v3M3 13h18',
        'game' => AppIcons.game,
        'food' => AppIcons.food,
        'travel' =>
          'M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z',
        'heart' => AppIcons.heart,
        _ => AppIcons.sparkle,
      };
}

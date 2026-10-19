import '../../../core/widgets/app_icons.dart';

/// Profil grubuna özgü ikon yolları (24×24 SVG `d`), tasarım dosyalarından birebir.
abstract final class ProfileIcons {
  static const sliders = 'M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6';
  static const pencil = 'M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z';
  static const applications = 'M9 11l3 3 8-8M20 12v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h9';
  static const coupon =
      'M2 9a3 3 0 0 0 0 6v3a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-3a3 3 0 0 0 0-6V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2zM13 5v2M13 17v2M13 11v2';
  static const percent = 'M19 5 5 19M6.5 4a2.5 2.5 0 1 0 0 5 2.5 2.5 0 1 0 0-5zM17.5 15a2.5 2.5 0 1 0 0 5 2.5 2.5 0 1 0 0-5z';
  static const child =
      'M9 12h.01M15 12h.01M10 16c.5.3 1.2.5 2 .5s1.5-.2 2-.5M19 6.3a9 9 0 0 1 1.8 3.9 2 2 0 0 1 0 3.6 9 9 0 0 1-17.6 0 2 2 0 0 1 0-3.6A9 9 0 0 1 12 3c2 0 3.5 1.1 3.5 2.5s-.9 2.5-2 2.5c-.8 0-1.5-.4-1.5-1';
  static const chat = 'M21 11.5a8.4 8.4 0 0 1-12.4 7.4L3 21l2-5.4A8.4 8.4 0 1 1 21 11.5z';
  static const document = 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM14 2v6h6M8 13h8M8 17h8';
  static const file = 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM14 2v6h6';
  static const logout = 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9';
  static const upload = 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12';
  static const warn = 'M12 2 2 20h20zM12 9v4M12 17h.01';
  static const alert = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM12 8v5M12 16h.01';
  static const paperclip = 'm21.4 11-9.2 9.2a6 6 0 0 1-8.5-8.5l9.2-9.2a4 4 0 0 1 5.7 5.7l-9.2 9.2a2 2 0 0 1-2.8-2.8l8.5-8.5';
  static const museum = 'M3 21h18M5 21V10M19 21V10M9 21v-7M15 21v-7M2 10l10-7 10 7z';
  static const camp = 'M3 20h18M7 20l5-9 5 9M12 11V4l4 2-4 2';
  static const eye = 'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12zM12 9a3 3 0 1 0 0 6 3 3 0 1 0 0-6z';
  static const eyeOff =
      'M2 2l20 20M10.6 5.1A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3.2 4M6.6 6.6C3.8 8.4 2 12 2 12s3.5 7 10 7a9.7 9.7 0 0 0 5.4-1.6M9.9 9.9a3 3 0 0 0 4.2 4.2';

  /// API'deki rozet ikon anahtarı → yol. Bilinmeyen anahtar yıldız olur.
  static String badge(String key) => switch (key) {
    'flame' => AppIcons.flame,
    'museum' => museum,
    'camp' => camp,
    'trophy' => AppIcons.trophy,
    'steps' => AppIcons.steps,
    'book' => AppIcons.book,
    'music' => AppIcons.music,
    'mountain' => AppIcons.mountain,
    'ball' => AppIcons.ball,
    'heart' => AppIcons.heart,
    _ => AppIcons.sparkle,
  };
}

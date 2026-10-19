import '../../../core/widgets/app_icons.dart';

/// Keşfet / arama / bildirim / hikâye ikonları. API içerikleri ikonu anahtarla
/// verir (`"icon": "tent"`); bilinmeyen anahtar → [AppIcons.sparkle].
abstract final class HomeIcons {
  /// Bildirim "rezervasyon" bileti (Bildirimler.dc.html).
  static const ticket =
      'M2 9a3 3 0 0 0 0 6v3a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-3a3 3 0 0 0 0-6V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2zM13 5v2M13 17v2M13 11v2';

  /// Kazanım satırındaki BUAN jetonu (yuvarlatılmış kare + üçgen).
  static const coin = 'M3 9a6 6 0 0 1 6-6h6a6 6 0 0 1 6 6v6a6 6 0 0 1-6 6H9a6 6 0 0 1-6-6zM10 8.2l5.6 3.8-5.6 3.8z';

  /// Hikâye CTA oku.
  static const arrowRight = 'M5 12h14M12 5l7 7-7 7';

  /// Arama sonucu "fırsat" etiketi (delikli olmayan sürüm).
  static const tagPlain =
      'M12.6 2.6A2 2 0 0 0 11.2 2H4a2 2 0 0 0-2 2v7.2a2 2 0 0 0 .6 1.4l8.7 8.7a2.4 2.4 0 0 0 3.4 0l6.6-6.6a2.4 2.4 0 0 0 0-3.4z';

  static const _byKey = <String, String>{
    'tag': AppIcons.tag,
    'tent': AppIcons.tent,
    'music': AppIcons.music,
    'megaphone': AppIcons.megaphone,
    'mountain': AppIcons.mountain,
    'map': AppIcons.map,
    'calendar': AppIcons.calendar,
    'pool': AppIcons.pool,
    'ball': AppIcons.ball,
    'tennis': AppIcons.tennis,
    'building': AppIcons.building,
    'game': AppIcons.game,
    'poll': AppIcons.poll,
    'steps': AppIcons.steps,
    'play': AppIcons.playCircle,
    'question': AppIcons.question,
    'flame': AppIcons.flame,
    'trophy': AppIcons.trophy,
    'gift': AppIcons.gift,
    'pin': AppIcons.pin,
    'camera': AppIcons.camera,
    'qr': AppIcons.qr,
    'bus': AppIcons.bus,
    'book': AppIcons.book,
    'cap': AppIcons.cap,
    'heart': AppIcons.heart,
    'sparkle': AppIcons.sparkle,
    'coin': coin,
    'ticket': ticket,
  };

  static String of(String key) => _byKey[key] ?? AppIcons.sparkle;
}

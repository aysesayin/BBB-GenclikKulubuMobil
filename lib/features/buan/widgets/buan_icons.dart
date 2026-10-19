import '../../../core/widgets/app_icons.dart';
import '../../../data/models/buan/buan_task.dart';

/// BUAN ekranlarına özgü ikon yolları (tasarım dosyalarındaki `d` dizeleri birebir).
abstract final class BuanIcons {
  static const step =
      'M4 16v-2.4C4 11.5 3 10.5 3 8c0-2.7 1.5-6 4.5-6C9.4 2 10 3.8 10 5.5c0 3.1-2 5.7-2 8.7V16a2 2 0 1 1-4 0zM20 20v-2.4c0-2.1 1-3.1 1-5.6 0-2.7-1.5-6-4.5-6C14.6 6 14 7.8 14 9.5c0 3.1 2 5.7 2 8.7V20a2 2 0 1 0 4 0z';
  static const stepSingle = 'M4 16v-2.4C4 11.5 3 10.5 3 8c0-2.7 1.5-6 4.5-6C9.4 2 10 3.8 10 5.5c0 3.1-2 5.7-2 8.7V16a2 2 0 1 1-4 0z';
  static const play = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM10 8l6 4-6 4z';
  static const wheel = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM12 2v20M2 12h20M4.9 4.9l14.2 14.2M19.1 4.9 4.9 19.1';
  static const quiz = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM9.1 9a3 3 0 0 1 5.8 1c0 2-3 3-3 3M12 17h.01';
  static const idea = 'M9 18h6M10 22h4M12 2a7 7 0 0 0-4 12.7V17h8v-2.3A7 7 0 0 0 12 2z';
  static const invite = 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 3a4 4 0 1 0 0 8 4 4 0 1 0 0-8zM19 8v6M22 11h-6';
  static const heart =
      'M19 14c1.5-1.5 3-3.2 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.8 0-3 .5-4.5 2-1.5-1.5-2.7-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4 3 5.5l7 7z';
  static const brief = 'M3 7h18v13H3zM8 7V4h8v3M3 13h18';
  static const at = 'M12 8a4 4 0 1 0 0 8 4 4 0 1 0 0-8zM16 12v1.5a2.5 2.5 0 0 0 5 0V12a9 9 0 1 0-3.5 7.1';
  static const qr = 'M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h3v3h-3zM21 21h-4v-4';
  static const cam =
      'M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3zM12 10a3 3 0 1 0 0 6 3 3 0 1 0 0-6z';
  static const tag =
      'M12.6 2.6A2 2 0 0 0 11.2 2H4a2 2 0 0 0-2 2v7.2a2 2 0 0 0 .6 1.4l8.7 8.7a2.4 2.4 0 0 0 3.4 0l6.6-6.6a2.4 2.4 0 0 0 0-3.4z';
  static const arrowRight = 'M5 12h14M12 5l7 7-7 7';
  static const arrowUp = 'M12 19V5M5 12l7-7 7 7';
  static const arrowDown = 'M12 5v14M5 12l7 7 7-7';
  static const flat = 'M5 12h14';
  static const trophy = 'M6 9H4.5a2.5 2.5 0 0 1 0-5H6M18 9h1.5a2.5 2.5 0 0 0 0-5H18M4 22h16M18 2H6v7a6 6 0 0 0 12 0zM12 15v7';
  static const giftOpen = 'M3 8h18v4H3zM12 8v13M19 12v9H5v-9M7.5 8a2.5 2.5 0 0 1 0-5C11 3 12 8 12 8s1-5 4.5-5a2.5 2.5 0 0 1 0 5';

  // Pazar
  static const game =
      'M6 11h4M8 9v4M15 12h.01M18 10h.01M17.3 5H6.7a4 4 0 0 0-4 3.6L2 15a3 3 0 0 0 5.4 2l1.6-2h6l1.6 2a3 3 0 0 0 5.4-2l-.7-6.4A4 4 0 0 0 17.3 5z';
  static const bag = 'M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4zM3 6h18M16 10a4 4 0 0 1-8 0';
  static const cable = 'M3 20h18M6 20V9l6-5 6 5v11M12 4V2M9 13h6';
  static const shirt =
      'M20.4 6.6 16 4l-2 2h-4L8 4 3.6 6.6a1 1 0 0 0-.4 1.2l1.4 3.4a1 1 0 0 0 1.2.6L7 11.4V20a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-8.6l1.2.4a1 1 0 0 0 1.2-.6l1.4-3.4a1 1 0 0 0-.6-1.2z';
  static const lang = 'M5 8l6 6M4 14l6-6 2-3M2 5h12M7 2h1M22 22l-5-10-5 10M14 18h6';

  // Rozetler
  static const museum = 'M3 21h18M5 21V10M19 21V10M9 21v-7M15 21v-7M2 10l10-7 10 7z';
  static const users =
      'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 3a4 4 0 1 0 0 8 4 4 0 1 0 0-8zM22 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8';
  static const campfire = 'M3 20h18M7 20l5-9 5 9M12 11V4l4 2-4 2';
  static const waves =
      'M2 18c2 0 2-1.5 4-1.5S8 18 10 18s2-1.5 4-1.5 2 1.5 4 1.5 2-1.5 4-1.5M2 13c2 0 2-1.5 4-1.5S8 13 10 13s2-1.5 4-1.5 2 1.5 4 1.5 2-1.5 4-1.5';
  static const star = 'M12 2l3.1 6.3 6.9 1-5 4.9 1.2 6.8L12 17.8 5.8 21l1.2-6.8-5-4.9 6.9-1z';

  /// Görev türü → ikon.
  static String task(BuanTaskType type) => switch (type) {
    BuanTaskType.steps => step,
    BuanTaskType.watch => play,
    BuanTaskType.spin => wheel,
    BuanTaskType.quiz => quiz,
    BuanTaskType.idea => idea,
    BuanTaskType.invite => invite,
    BuanTaskType.volunteer => heart,
    BuanTaskType.biko => brief,
    BuanTaskType.follow => at,
    BuanTaskType.qr => qr,
    BuanTaskType.photo => cam,
    BuanTaskType.useOpportunity => tag,
    BuanTaskType.unknown => AppIcons.sparkle,
  };

  /// API ikon anahtarı → yol (ödül ve rozetler). Bilinmeyen → hediye.
  static String byKey(String key) => switch (key) {
    'game' => game,
    'bag' => bag,
    'book' => AppIcons.book,
    'cable' => cable,
    'shirt' => shirt,
    'cap' => AppIcons.cap,
    'lang' => lang,
    'lunch' => AppIcons.food,
    'step' => stepSingle,
    'flame' => AppIcons.flame,
    'museum' => museum,
    'tag' => tag,
    'quiz' => quiz,
    'users' => users,
    'campfire' => campfire,
    'building' => AppIcons.building,
    'mountain' => AppIcons.mountain,
    'heart' => heart,
    'waves' => waves,
    'trophy' => trophy,
    'camera' => cam,
    'star' => star,
    _ => giftOpen,
  };
}

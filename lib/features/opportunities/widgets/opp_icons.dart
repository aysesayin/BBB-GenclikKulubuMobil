import '../../../core/widgets/app_icons.dart';

/// Fırsatlar özelliğine özgü ikon yolları (FirsatListe / FirsatDetay / FirsatYakalandi).
abstract final class OppIcons {
  /// Detay başlığındaki paylaş (yukarı ok + kutu).
  static const share = 'M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8M16 6l-4-4-4 4M12 2v13';

  /// Yakalandı ekranındaki "Kodu kopyala".
  static const copy = 'M8 8h12v12H8zM4 16V4h12';

  /// "Parlaklık %100" güneşi.
  static const sun =
      'M12 8a4 4 0 1 0 0 8 4 4 0 1 0 0-8zM12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M6.3 17.7l-1.4 1.4M19.1 4.9l-1.4 1.4';

  /// Puanlama yıldızı (5 köşeli, dolu/boş).
  static const star = 'M12 2.5l2.9 6.1 6.6.8-4.9 4.6 1.3 6.6L12 17.3l-5.9 3.3 1.3-6.6L2.5 9.4l6.6-.8z';

  /// Kategori ikon anahtarı (API `icon`) → yol.
  static String byKey(String key) => switch (key) {
    'bus' => AppIcons.bus,
    'game' => AppIcons.game,
    'food' => AppIcons.food,
    'book' => AppIcons.book,
    'cap' => AppIcons.cap,
    'ball' => AppIcons.ball,
    'phone' => AppIcons.phone,
    'sparkle' => AppIcons.sparkle,
    'health' => AppIcons.health,
    'music' => AppIcons.music,
    'tent' => AppIcons.tent,
    _ => AppIcons.grid,
  };
}

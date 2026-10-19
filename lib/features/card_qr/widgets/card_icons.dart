/// Kartım / QR Okut ekranlarına özgü ikon yolları (Kartim.dc.html, QROkut.dc.html).
abstract final class CardIcons {
  /// "QR Okut" butonu (tarama çerçevesi).
  static const scan = 'M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2M7 12h10';

  /// "Parlaklık arttı" çipi.
  static const sun = 'M12 8a4 4 0 1 0 0 8 4 4 0 1 0 0-8zM12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2';

  /// El feneri.
  static const torch = 'M18 6c0 2-2 2-2 4v10a2 2 0 0 1-2 2h-4a2 2 0 0 1-2-2V10c0-2-2-2-2-4V2h12zM6 6h12M12 12v.01';

  /// "Kartımı göster" (küçük QR).
  static const qrSmall = 'M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h3v3h-3zM21 21h-4v-4';

  /// "Galeriden".
  static const gallery = 'M3 5h18v14H3zM3 15l5-5 5 5M14 13l2-2 5 5';
}

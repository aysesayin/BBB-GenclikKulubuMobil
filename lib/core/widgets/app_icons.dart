/// Ortak ikon yolları (SVG `d`, 24×24). Tasarım dosyalarından birebir alınmıştır.
/// Özelliğe özgü ikonlar ilgili `features/<x>/widgets/<x>_icons.dart` dosyasında tutulur.
abstract final class AppIcons {
  // Navigasyon
  static const compass = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM16.2 7.8l-2.1 6.3-6.3 2.1 2.1-6.3z';
  static const tag =
      'M12.6 2.6A2 2 0 0 0 11.2 2H4a2 2 0 0 0-2 2v7.2a2 2 0 0 0 .6 1.4l8.7 8.7a2.4 2.4 0 0 0 3.4 0l6.6-6.6a2.4 2.4 0 0 0 0-3.4zM7.5 6a1.5 1.5 0 1 0 0 3 1.5 1.5 0 1 0 0-3z';
  static const qr =
      'M3 4.5A1.5 1.5 0 0 1 4.5 3h4A1.5 1.5 0 0 1 10 4.5v4A1.5 1.5 0 0 1 8.5 10h-4A1.5 1.5 0 0 1 3 8.5zM14 4.5A1.5 1.5 0 0 1 15.5 3h4A1.5 1.5 0 0 1 21 4.5v4a1.5 1.5 0 0 1-1.5 1.5h-4A1.5 1.5 0 0 1 14 8.5zM3 15.5A1.5 1.5 0 0 1 4.5 14h4a1.5 1.5 0 0 1 1.5 1.5v4A1.5 1.5 0 0 1 8.5 21h-4A1.5 1.5 0 0 1 3 19.5zM14 14h3v3h-3zM21 14v.01M14 21h.01M17 21h4v-4';
  static const buanTab = 'M9 3h6a6 6 0 0 1 6 6v6a6 6 0 0 1-6 6H9a6 6 0 0 1-6-6V9a6 6 0 0 1 6-6zM10 8.2l5.6 3.8-5.6 3.8z';
  static const user = 'M12 4a4 4 0 1 0 0 8 4 4 0 1 0 0-8zM4 21c0-4 3.6-6 8-6s8 2 8 6';
  static const back = 'M19 12H5M12 19l-7-7 7-7';
  static const chevronRight = 'M9 18l6-6-6-6';
  static const chevronDown = 'M6 9l6 6 6-6';
  static const close = 'M18 6 6 18M6 6l12 12';

  // Genel
  static const search = 'M11 3a8 8 0 1 0 0 16 8 8 0 1 0 0-16zM21 21l-4.3-4.3';
  static const bell = 'M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10.3 21a1.9 1.9 0 0 0 3.4 0';
  static const heart =
      'M19 14c1.5-1.5 3-3.2 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.8 0-3 .5-4.5 2-1.5-1.5-2.7-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4 3 5.5l7 7z';
  static const clock = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM12 6v6l4 2';
  static const pin = 'M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0zM12 7a3 3 0 1 0 0 6 3 3 0 1 0 0-6z';
  static const pinSimple = 'M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0z';
  static const sparkle = 'M12 3l1.9 5.8L20 10l-6.1 1.2L12 17l-1.9-5.8L4 10l6.1-1.2z';
  static const filter = 'M22 3H2l8 9.5V19l4 2v-8.5z';
  static const grid = 'M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z';
  static const check = 'M20 6 9 17l-5-5';
  static const plus = 'M12 5v14M5 12h14';
  static const minus = 'M5 12h14';
  static const copy = 'M9 9h11v11H9zM5 15H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v1';
  static const share = 'M18 2a3 3 0 1 0 0 6 3 3 0 1 0 0-6zM6 9a3 3 0 1 0 0 6 3 3 0 1 0 0-6zM18 16a3 3 0 1 0 0 6 3 3 0 1 0 0-6zM8.6 13.5l6.8 4M15.4 6.5l-6.8 4';
  static const lock = 'M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4';
  static const info = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM12 16v-4M12 8h.01';
  static const wallet =
      'M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4';
  static const wifiOff =
      'M2 2l20 20M8.5 16.5a5 5 0 0 1 7 0M2 8.8a15 15 0 0 1 4.2-2.6M10.7 5.1A15 15 0 0 1 22 8.8M5 12.9a10 10 0 0 1 5.2-2.7M16.8 11.2a10 10 0 0 1 2.2 1.7M12 20h.01';
  static const refresh = 'M21 12a9 9 0 1 1-6.2-8.6M21 3v6h-6';
  static const settings =
      'M12 9a3 3 0 1 0 0 6 3 3 0 1 0 0-6zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z';
  static const camera = 'M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2zM12 9a4 4 0 1 0 0 8 4 4 0 1 0 0-8z';
  static const gift = 'M20 12v10H4V12M2 7h20v5H2zM12 22V7M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7zM12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z';

  // Oyunlaştırma
  static const flame =
      'M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.4-.5-2-1-3-1.1-2.1-.2-4 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.2.4-2.3 1-3.3.6 1.2 1.6 2.3 2.5 2.8z';
  static const trophy =
      'M6 9H4.5a2.5 2.5 0 0 1 0-5H6M18 9h1.5a2.5 2.5 0 0 0 0-5H18M4 22h16M10 14.7V17c0 .6-.5 1-1 1.2C7.8 18.8 7 20.2 7 22M14 14.7V17c0 .6.5 1 1 1.2 1.2.6 2 2 2 3.8M18 2H6v7a6 6 0 0 0 12 0z';
  static const steps =
      'M4 16v-2.4C4 11.5 3 10.5 3 8c0-2.7 1.5-6 4.5-6C9.4 2 10 3.8 10 5.5c0 3.1-2 5.7-2 8.7V16a2 2 0 1 1-4 0zM20 20v-2.4c0-2.1 1-3.1 1-5.6 0-2.7-1.5-6-4.5-6C14.6 6 14 7.8 14 9.5c0 3.1 2 5.7 2 8.7V20a2 2 0 1 0 4 0z';
  static const playCircle = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM10 8l6 4-6 4z';
  static const question = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM9.1 9a3 3 0 0 1 5.8 1c0 2-3 3-3 3M12 17h.01';

  // Kısayol / kategori
  static const map = 'M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2zM9 4v14M15 6v14';
  static const calendar = 'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zM4 10h16M8 2v4M16 2v4';
  static const pool =
      'M2 18c2 0 2-1.5 4-1.5S8 18 10 18s2-1.5 4-1.5 2 1.5 4 1.5 2-1.5 4-1.5M2 13c2 0 2-1.5 4-1.5S8 13 10 13s2-1.5 4-1.5 2 1.5 4 1.5 2-1.5 4-1.5M8 9V5a2 2 0 0 1 4 0M14 9V5a2 2 0 0 1 4 0';
  static const ball = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20';
  static const tennis = 'M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20zM5 5c3.5 3.5 3.5 10.5 0 14M19 5c-3.5 3.5-3.5 10.5 0 14';
  static const building = 'M3 21h18M5 21V8l7-5 7 5v13M9 21v-6h6v6M10 10h4';
  static const game =
      'M6 11h4M8 9v4M15 12h.01M18 10h.01M17.3 5H6.7a4 4 0 0 0-4 3.6L2 15a3 3 0 0 0 5.4 2l1.6-2h6l1.6 2a3 3 0 0 0 5.4-2l-.7-6.4A4 4 0 0 0 17.3 5z';
  static const poll = 'M5 20V11M11 20V5M17 20v-6M3 20h18';
  static const bus =
      'M8 6v6M16 6v6M2 12h20M7 18h.01M17 18h.01M4 4h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2zM6 18v3M18 18v3';
  static const food = 'M3 2v7a3 3 0 0 0 6 0V2M6 2v20M18 15V2a5 5 0 0 0-3 5v6a2 2 0 0 0 2 2zM18 15v7';
  static const book = 'M4 19.5A2.5 2.5 0 0 1 6.5 17H20V3H6.5A2.5 2.5 0 0 0 4 5.5zM20 17v5H6.5A2.5 2.5 0 0 1 4 19.5';
  static const cap = 'M22 10 12 5 2 10l10 5zM6 12v5c3 2 9 2 12 0v-5';
  static const phone = 'M5 2h14v20H5zM12 18h.01';
  static const health =
      'M19 14c1.5-1.5 3-3.2 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.8 0-3 .5-4.5 2-1.5-1.5-2.7-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4 3 5.5l7 7zM9 11h6M12 8v6';
  static const tent = 'M3 20 12 4l9 16zM12 4v16M8 20l4-6 4 6';
  static const music = 'M9 18V5l12-2v13M9 18a3 3 0 1 1-6 0 3 3 0 0 1 6 0zM21 16a3 3 0 1 1-6 0 3 3 0 0 1 6 0z';
  static const megaphone = 'M3 11v2a1 1 0 0 0 1 1h3l5 4V6L7 10H4a1 1 0 0 0-1 1zM16 9a4 4 0 0 1 0 6M19 6a8 8 0 0 1 0 12';
  static const mountain = 'M8 3l4 8 5-5 5 15H2z';
}

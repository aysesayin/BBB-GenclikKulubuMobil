import 'package:flutter/material.dart';

/// Tipografi: başlıklar Baloo 2 (yuvarlak, enerjik), gövde Nunito.
/// Sayılar her zaman tabular rakamla ([AppTypography.number]).
abstract final class AppFonts {
  static const display = 'Baloo2';
  static const body = 'Nunito';
  static const script = 'Caveat';

  /// Dar poster başlığı (giriş akışı kinetik tipografi).
  static const poster = 'Anton';
}

abstract final class AppTypography {
  static const _tabular = [FontFeature.tabularFigures()];

  /// Baloo 2 başlık stili. Tasarımda 19–34 px, 800 ağırlık.
  static TextStyle display(double size, {FontWeight weight = FontWeight.w800, Color? color, double height = 1.1}) =>
      TextStyle(fontFamily: AppFonts.display, fontSize: size, fontWeight: weight, height: height, color: color);

  /// Nunito gövde stili.
  static TextStyle body(double size, {FontWeight weight = FontWeight.w700, Color? color, double? height}) =>
      TextStyle(fontFamily: AppFonts.body, fontSize: size, fontWeight: weight, height: height, color: color);

  /// Tabular rakamlı sayı (BUAN bakiyesi, sayaçlar, kontenjan).
  static TextStyle number(double size, {FontWeight weight = FontWeight.w900, Color? color, double? height}) => TextStyle(
        fontFamily: AppFonts.body,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
        fontFeatures: _tabular,
      );

  /// Anton poster başlığı (giriş akışı). Tek ağırlık (400).
  static TextStyle poster(double size, {Color? color, double height = .9, double letterSpacing = -.5}) =>
      TextStyle(fontFamily: AppFonts.poster, fontSize: size, fontWeight: FontWeight.w400, height: height, letterSpacing: letterSpacing, color: color);

  /// El yazısı logo satırı ("Bursa Büyükşehir").
  static TextStyle script(double size, {Color? color}) =>
      TextStyle(fontFamily: AppFonts.script, fontSize: size, fontWeight: FontWeight.w700, height: .9, color: color);

  // ---- Adlandırılmış ölçek (tasarımda en sık kullanılanlar) ----
  /// Sekme ekranı başlığı: "Fırsatlar", "BUAN" — 30/800.
  static TextStyle get screenTitle => display(30);

  /// Geri butonlu alt ekran başlığı — 26/800.
  static TextStyle get pageTitle => display(26);

  /// Bölüm başlığı: "Bugünün Görevleri" — 21/800.
  static TextStyle get sectionTitle => display(21);

  /// Kart başlığı — Nunito 15/800.
  static TextStyle get cardTitle => body(15, weight: FontWeight.w800, height: 1.25);

  /// Gövde metni — 15/700.
  static TextStyle get bodyM => body(15, height: 1.4);

  /// Etiket — 12/800 (kısayol, chip altı).
  static TextStyle get label => body(12, weight: FontWeight.w800);

  /// Açıklama / yardımcı metin — 13/700.
  static TextStyle get caption => body(13);

  /// Buton — 17/900 (56 px) ve 15/900 (48 px).
  static TextStyle get buttonL => body(17, weight: FontWeight.w900);
  static TextStyle get buttonM => body(15, weight: FontWeight.w900);

  static TextTheme textTheme(Color ink, Color mut) => TextTheme(
        displayLarge: display(34, color: ink),
        displayMedium: display(30, color: ink),
        displaySmall: display(26, color: ink),
        headlineMedium: display(22, color: ink),
        headlineSmall: display(21, color: ink),
        titleLarge: display(19, color: ink),
        titleMedium: body(16, weight: FontWeight.w800, color: ink),
        titleSmall: body(15, weight: FontWeight.w800, color: ink),
        bodyLarge: body(16, weight: FontWeight.w600, color: ink),
        bodyMedium: body(15, color: ink),
        bodySmall: body(13, color: mut),
        labelLarge: body(15, weight: FontWeight.w900, color: ink),
        labelMedium: body(13, weight: FontWeight.w800, color: ink),
        labelSmall: body(11, weight: FontWeight.w800, color: mut),
      );
}

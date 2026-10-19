import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_palette.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.teal,
      onPrimary: p.isDark ? p.bg : p.paper,
      secondary: p.secondary,
      onSecondary: p.onTile,
      tertiary: p.buanFill,
      onTertiary: p.onBuan,
      error: p.errorText,
      onError: p.paper,
      surface: p.sf,
      onSurface: p.ink,
      surfaceContainerHighest: p.sf2,
      outline: p.line,
      outlineVariant: p.line,
      shadow: p.shadowColor,
      scrim: p.scrim,
    );
    final text = AppTypography.textTheme(p.ink, p.mut);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      fontFamily: AppFonts.body,
      textTheme: text,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: p.ink,
        titleTextStyle: AppTypography.pageTitle.copyWith(color: p.ink),
        systemOverlayStyle: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.sf,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.sf,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.sf,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.body(16, weight: FontWeight.w600, color: p.mut),
        // Tek durum-duyarlı çerçeve: `border: InputBorder.none` / `.collapsed` veren özel alanlar
        // (OTP kutuları, yüzen etiketli alan) temanın çerçevesini devralmaz.
        border: WidgetStateInputBorder.resolveWith((states) {
          if (states.contains(WidgetState.error)) return _border(p.errorText);
          if (states.contains(WidgetState.focused)) return _border(p.teal);
          return _border(p.line);
        }),
        errorStyle: AppTypography.body(12, weight: FontWeight.w800, color: p.errorText),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.paper : p.borderStrong),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.teal : p.sf2),
        trackOutlineColor: WidgetStatePropertyAll(p.line),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.teal : Colors.transparent),
        side: BorderSide(color: p.borderStrong, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.chip,
        contentTextStyle: AppTypography.body(14, weight: FontWeight.w800, color: p.onChip),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }

  static OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: c, width: 2),
      );
}

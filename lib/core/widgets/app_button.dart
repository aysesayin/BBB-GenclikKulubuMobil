import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import 'app_icon.dart';

enum AppButtonVariant {
  /// Sarı CTA, ink metin, altta 4 px "kabartma" gölge — "Fırsatı Yakala".
  cta,

  /// Mor BUAN dolgu, beyaz metin — "BUAN ile Al".
  buan,

  /// Turkuaz 2 px çerçeve — "Takvime ekle".
  outline,

  /// Ink 2 px çerçeve (nötr ikincil) — "Kartımı göster".
  outlineInk,

  /// Açık gri (`line`) 2 px çerçeve, ink metin — "Vazgeç", "Giriş yap".
  outlineLine,

  /// Yalnız metin — "Misafir olarak gez".
  text,
}

enum AppButtonSize { large, medium, small }

/// Tasarım sistemi butonu: 56 / 48 / 40 px, tam yuvarlak.
/// [onPressed] null → pasif ("Kontenjan dolu").
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.cta,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.busy = false,
    this.expand = true,
    this.semanticLabel,
    this.fontSize,
  });

  const AppButton.buan({super.key, required this.label, required this.onPressed, this.size = AppButtonSize.large, this.icon, this.trailingIcon, this.busy = false, this.expand = true, this.semanticLabel, this.fontSize})
      : variant = AppButtonVariant.buan;

  const AppButton.outline({super.key, required this.label, required this.onPressed, this.size = AppButtonSize.medium, this.icon, this.trailingIcon, this.busy = false, this.expand = true, this.semanticLabel, this.fontSize})
      : variant = AppButtonVariant.outline;

  const AppButton.text({super.key, required this.label, required this.onPressed, this.size = AppButtonSize.medium, this.icon, this.trailingIcon, this.busy = false, this.expand = true, this.semanticLabel, this.fontSize})
      : variant = AppButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final String? icon;

  /// Metnin sağında ikon (ör. "Detaya git →").
  final String? trailingIcon;
  final bool busy;
  final bool expand;
  final String? semanticLabel;

  /// Metin boyutu (varsayılan 56 px → 17, diğerleri → 15). Yan yana iki buton için 15–16.
  final double? fontSize;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  double get _height => switch (widget.size) {
        AppButtonSize.large => 56,
        AppButtonSize.medium => 48,
        AppButtonSize.small => 40,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = widget.onPressed != null && !widget.busy;
    final disabled = widget.onPressed == null;
    final (Color bg, Color fg, Color? shadow, Color? border) = switch (widget.variant) {
      _ when disabled => (p.sf2, p.mut, null, null),
      AppButtonVariant.cta => (p.cta, p.onCta, p.ctaShadow, null),
      AppButtonVariant.buan => (p.buanFill, p.onBuan, p.buanShadow, null),
      AppButtonVariant.outline => (Colors.transparent, p.teal, null, p.teal),
      AppButtonVariant.outlineInk => (Colors.transparent, p.ink, null, p.ink),
      AppButtonVariant.outlineLine => (Colors.transparent, p.ink, null, p.line),
      AppButtonVariant.text => (Colors.transparent, p.teal, null, null),
    };
    final base = widget.size == AppButtonSize.large ? AppTypography.buttonL : AppTypography.buttonM;
    final style = widget.fontSize == null ? base : base.copyWith(fontSize: widget.fontSize);
    final lift = shadow != null && !_down ? 4.0 : (shadow != null ? 2.0 : 0.0);

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.busy)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 3, color: fg)),
          )
        else if (widget.icon != null)
          Padding(padding: const EdgeInsets.only(right: 8), child: AppIcon(widget.icon!, size: 20, color: fg, strokeWidth: 2.4)),
        Flexible(
          child: Text(widget.label, style: style.copyWith(color: fg), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (widget.trailingIcon != null && !widget.busy)
          Padding(padding: const EdgeInsets.only(left: 8), child: AppIcon(widget.trailingIcon!, size: 20, color: fg, strokeWidth: 2.4)),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: enabled
            ? () {
                Haptics.light();
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: _height,
          margin: EdgeInsets.only(top: shadow == null ? 0 : 4 - lift, bottom: lift),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(_height / 2),
            border: border == null ? null : Border.all(color: border, width: 2),
            boxShadow: shadow == null ? null : [BoxShadow(color: shadow, offset: Offset(0, lift))],
          ),
          child: content,
        ),
      ),
    );
  }
}

/// 44×44 yuvarlak ikon butonu (geri, ara, zil…). Erişilebilirlik etiketi zorunlu.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.background,
    this.color,
    this.shadow = false,
    this.badge = false,
    this.size = 44,
    this.iconSize = 22,
  });

  final String icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? background, color;
  final bool shadow;

  /// Sağ üstte okunmamış noktası.
  final bool badge;
  final double size, iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: onPressed,
          radius: size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              boxShadow: shadow ? p.cardShadow : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppIcon(icon, size: iconSize, color: color ?? p.ink, strokeWidth: 2.3),
                if (badge)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: p.hotFill,
                        shape: BoxShape.circle,
                        border: Border.all(color: background ?? p.sf, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

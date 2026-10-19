import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'app_icon.dart';
import 'app_icons.dart';

/// Yüzey kartı: r22, `sh` gölgesi. [onTap] verilirse dokunulabilir.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.radius = AppRadii.lg, this.color, this.semanticLabel, this.clip = false});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final String? semanticLabel;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final br = BorderRadius.circular(radius);
    Widget body = Padding(padding: padding, child: child);
    if (onTap != null) {
      body = Material(type: MaterialType.transparency, child: InkWell(onTap: onTap, borderRadius: br, child: body));
    }
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color ?? p.sf, borderRadius: br, boxShadow: p.cardShadow),
        child: clip ? ClipRRect(borderRadius: br, child: body) : body,
      ),
    );
  }
}

/// Pastel kare ikon karosu (kısayol / kategori): 58×58, r20, ink ikon.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color, this.size = 58, this.radius = AppRadii.tile, this.iconSize = 26, this.border, this.shadow});

  final String icon;
  final Color color;
  final double size, radius, iconSize;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), border: border, boxShadow: shadow),
        alignment: Alignment.center,
        child: AppIcon(icon, size: iconSize, color: context.palette.onTile, strokeWidth: 2),
      );
}

/// Bölüm başlığı + "Tümü" bağlantısı.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction, this.padding = AppSpacing.screenPadding});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: AppTypography.sectionTitle.copyWith(color: p.ink)))),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 4), foregroundColor: p.teal),
              child: Text(actionLabel ?? context.l10n.commonSeeAll, style: AppTypography.body(14, weight: FontWeight.w800, color: p.teal)),
            ),
        ],
      ),
    );
  }
}

/// Alt ekran başlığı: 44 px geri + Baloo başlık + sağ aksiyonlar.
/// Tasarımdaki `padding: 52px 20px 0 8px` → güvenli alan + 8 px.
class AppBackHeader extends StatelessWidget {
  const AppBackHeader({super.key, required this.title, this.trailing = const [], this.onBack, this.titleSize = 26, this.color});

  final String title;
  final List<Widget> trailing;
  final VoidCallback? onBack;
  final double titleSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = color ?? p.ink;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 20, 0),
      child: Row(
        children: [
          AppIconButton(
            icon: AppIcons.back,
            semanticLabel: context.l10n.commonBack,
            color: fg,
            iconSize: 24,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.display(titleSize, color: fg)),
            ),
          ),
          for (final t in trailing) ...[const SizedBox(width: 8), t],
        ],
      ),
    );
  }
}

/// Sekme ekranı başlığı ("Fırsatlar", "BUAN"): 30 px, güvenli alan + 12.
class TabScreenHeader extends StatelessWidget {
  const TabScreenHeader({super.key, required this.title, this.trailing = const []});

  final String title;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 16, 0),
        child: Row(
          children: [
            Expanded(child: Semantics(header: true, child: Text(title, style: AppTypography.screenTitle.copyWith(color: context.palette.ink)))),
            for (final t in trailing) ...[const SizedBox(width: 8), t],
          ],
        ),
      );
}

/// Sayfa altındaki yapışkan CTA alanı (detay ekranları).
class StickyBottomBar extends StatelessWidget {
  const StickyBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(color: p.sf, border: Border(top: BorderSide(color: p.line))),
      child: child,
    );
  }
}

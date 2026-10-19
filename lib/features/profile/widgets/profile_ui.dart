import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'profile_icons.dart';

/// Profil grubu ekranlarında ortak küçük parçalar.

/// "İLETİŞİM VE GÜVENLİK" tarzı küçük büyük-harf bölüm etiketi (13/900, .6 aralık).
class CapsLabel extends StatelessWidget {
  const CapsLabel(this.text, {super.key, this.padding = EdgeInsets.zero});

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: AppTypography.body(13, weight: FontWeight.w900, color: context.palette.mut).copyWith(letterSpacing: .6),
      ),
    ),
  );
}

/// Durum hapı: ikon + metin (yalnız renkle değil). 26 px, r13.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.fontSize = 12,
  });

  final String label, icon;
  final Color background, foreground;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    height: 26,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(13)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 12, color: foreground, strokeWidth: 3),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AppTypography.body(fontSize, weight: FontWeight.w900, color: foreground),
        ),
      ],
    ),
  );
}

/// Başlık + açıklama çifti (liste satırlarının sol tarafı).
class TitleSubtitle extends StatelessWidget {
  const TitleSubtitle({
    super.key,
    required this.title,
    this.subtitle,
    this.titleSize = 15,
    this.titleWeight = FontWeight.w900,
    this.subtitleSize = 12,
  });

  final String title;
  final String? subtitle;
  final double titleSize, subtitleSize;
  final FontWeight titleWeight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTypography.body(titleSize, weight: titleWeight, color: p.ink),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTypography.body(subtitleSize, color: p.mut)),
        ],
      ],
    );
  }
}

/// Uyarı kutusu (role=alert): pembe zemin, daire-ünlem ikon.
class InlineAlert extends StatelessWidget {
  const InlineAlert(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: p.pinkS, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(ProfileIcons.alert, size: 18, color: p.pinkT, strokeWidth: 2.6),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body(13, weight: FontWeight.w800, color: p.pinkT, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yüzey kartı içinde satırlar arası 1 px çizgili liste.
class DividedCard extends StatelessWidget {
  const DividedCard({
    super.key,
    required this.children,
    this.radius = AppRadii.lg,
    this.margin = AppSpacing.screenPadding,
    this.padding = EdgeInsets.zero,
    this.lineColor,
  });

  final List<Widget> children;
  final double radius;
  final EdgeInsetsGeometry margin, padding;
  final Color? lineColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: p.sf,
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: lineColor ?? p.line),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Snackbar kısayolu.
void showProfileSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Tarih biçimleri (tasarımdaki "30.06.2027", "12 Eki", "29 Ağu 2026").
abstract final class ProfileFmt {
  static String dmy(DateTime d) => DateFormat('dd.MM.yyyy').format(d.toLocal());
  static String dayMonth(DateTime d, String locale) => DateFormat('d MMM', locale).format(d.toLocal()).replaceAll('.', '');
  static String dayMonthYear(DateTime d, String locale) => DateFormat('d MMM y', locale).format(d.toLocal()).replaceAll('.', '');

  /// "30,00 ₺" — bakiye ve hareketler iki ondalıkla.
  static String money(num v, String locale) => NumberFormat.currency(locale: locale, symbol: '₺', decimalDigits: 2).format(v);
}

/// [ValidationIssue] → yerelleştirilmiş metin.
String validationText(AppLocalizations l, ValidationIssue issue, {int otpLength = 6}) => switch (issue) {
  ValidationIssue.required => l.profileErrRequired,
  ValidationIssue.tcknLength => l.profileErrTcknLength,
  ValidationIssue.tcknInvalid => l.profileErrTcknInvalid,
  ValidationIssue.phoneInvalid => l.profileErrPhone,
  ValidationIssue.emailInvalid => l.profileErrEmail,
  ValidationIssue.passwordWeak => l.profileErrPassword,
  ValidationIssue.otpLength => l.profileErrOtp(otpLength),
  ValidationIssue.underAge => l.profileChildOverAge,
};

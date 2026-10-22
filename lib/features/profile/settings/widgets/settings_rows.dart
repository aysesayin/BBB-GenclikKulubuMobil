import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/ui_prefs_controller.dart';
import '../../../../core/utils/haptics.dart';

/// Kolay modda satırlar 64 px ve başlıklar 17 px; normalde 60 / 15.
double settingsRowHeight(BuildContext context) => context.easyMode ? 64 : 60;
double settingsTitleSize(BuildContext context) => context.easyMode ? 17 : 15;

/// "Telefon · 0532 *** ** 90 · Değiştir" satırı (min 60 px, kolay modda 64).
class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({super.key, required this.title, required this.value, required this.action, required this.onTap});

  final String title, value, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: '$title, $value',
      hint: action,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: settingsRowHeight(context)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.body(settingsTitleSize(context), weight: FontWeight.w900, color: p.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(value, style: AppTypography.body(13, color: p.mut)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    action,
                    style: AppTypography.body(14, weight: FontWeight.w900, color: p.teal),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Başlık (+ açıklama) ve anahtar; satırın tamamı dokunulabilir.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final String title;
  final String? subtitle;
  final bool value;
  final EdgeInsetsGeometry padding;

  /// null → pasif.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final change = onChanged;
    return MergeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: change == null
              ? null
              : () {
                  Haptics.selection();
                  change(!value);
                },
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: settingsRowHeight(context)),
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.body(
                            settingsTitleSize(context),
                            weight: FontWeight.w900,
                            color: change == null ? p.mut : p.ink,
                          ),
                        ),
                        if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: AppTypography.body(12, color: p.mut))],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(value: value, onChanged: change),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

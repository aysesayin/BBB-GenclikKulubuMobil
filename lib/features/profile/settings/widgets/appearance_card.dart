import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/ui_prefs_controller.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/profile_ui.dart';
import '../../widgets/theme_mode_selector.dart';
import 'settings_rows.dart';

/// Görünüm kartı: en üstte Kolay Mod anahtarı (+ ileri yaş için kısa açıklama), altında tema,
/// dil segmenti ve yazı boyutu notu. [languageIndex] null ise dil segmenti gizlenir (misafir).
class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key, this.languageIndex, this.onLanguage});

  final int? languageIndex;
  final ValueChanged<int>? onLanguage;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final lang = languageIndex;
    final onLang = onLanguage;
    return DividedCard(
      children: [
        const EasyModeSwitchRow(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ThemeModeSelector(),
              if (lang != null && onLang != null) ...[
                const SizedBox(height: 14),
                LabeledSegment(
                  label: l.profileLanguage,
                  child: SegmentedTabs(labels: [l.profileLanguageTr, l.profileLanguageEn], index: lang, onChanged: onLang),
                ),
              ],
              const SizedBox(height: 14),
              Text(l.profileTextSizeNote, style: AppTypography.body(12, color: p.mut)),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Kolay Mod" anahtarı → [UiPrefsController.setEasyMode]; açılınca kısa bir toast gösterir.
class EasyModeSwitchRow extends StatelessWidget {
  const EasyModeSwitchRow({super.key});

  Future<void> _toggle(BuildContext context, bool on) async {
    final l = context.l10n;
    await context.read<UiPrefsController>().setEasyMode(on);
    if (on && context.mounted) showProfileSnack(context, l.easyModeOnToast);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final on = context.easyMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSwitchRow(
          title: l.easyModeTitle,
          subtitle: l.easyModeSubtitle,
          value: on,
          onChanged: (v) => _toggle(context, v),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            l.profileEasyModeHint,
            style: AppTypography.body(on ? 15 : 13, weight: FontWeight.w700, color: p.teal),
          ),
        ),
      ],
    );
  }
}

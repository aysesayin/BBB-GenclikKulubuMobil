import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';

/// "Tema" segmenti: Açık / Koyu / Sistem → [ThemeController.setMode].
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  static const _modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mode = context.select<ThemeController, ThemeMode>((t) => t.mode);
    return LabeledSegment(
      label: l.profileTheme,
      child: SegmentedTabs(
        labels: [l.profileThemeLight, l.profileThemeDark, l.profileThemeSystem],
        index: _modes.indexOf(mode),
        onChanged: (i) => context.read<ThemeController>().setMode(_modes[i]),
      ),
    );
  }
}

/// Başlık (15/900) + altında segment.
class LabeledSegment extends StatelessWidget {
  const LabeledSegment({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTypography.body(15, weight: FontWeight.w900, color: context.palette.ink),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

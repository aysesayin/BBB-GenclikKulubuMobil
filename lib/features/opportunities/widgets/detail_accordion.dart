import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';

/// Şartlar / Geçerlilik / Yaş sınırı akordeonu (tek bölüm açık).
class DetailAccordion extends StatelessWidget {
  const DetailAccordion({super.key, required this.sections, required this.expanded, required this.onToggle});

  final List<(String, List<String>)> sections;
  final int expanded;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < sections.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    button: true,
                    expanded: expanded == i,
                    child: InkWell(
                      onTap: () {
                        Haptics.selection();
                        onToggle(i);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sections[i].$1,
                                style: AppTypography.body(16, weight: FontWeight.w900, color: p.ink),
                              ),
                            ),
                            AnimatedRotation(
                              turns: expanded == i ? .5 : 0,
                              duration: AppDurations.fast,
                              child: AppIcon(AppIcons.chevronDown, size: 20, color: p.ink, strokeWidth: 2.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: AppDurations.fast,
                    alignment: Alignment.topCenter,
                    child: expanded == i ? _Bullets(items: sections[i].$2) : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = AppTypography.body(14, weight: FontWeight.w600, height: 1.5, color: p.mut);
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•', style: style),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: style)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

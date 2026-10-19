import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tasarımdaki zemin renkli alt CTA alanı (`padding: 12px 20px 30px; background: bg`).
class BottomCtaBar extends StatelessWidget {
  const BottomCtaBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: context.palette.bg,
      child: Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, bottom > 0 ? bottom : 18), child: child),
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'layout.dart';
import 'mascot.dart';

/// Geçici yer tutucu ekran (özellik henüz uygulanmadıysa). Üretimde kullanılmaz.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({super.key, required this.name, this.showBack = true});

  final String name;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            if (showBack) AppBackHeader(title: name) else TabScreenHeader(title: name),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Mascot(mood: MascotMood.sleepy), Text(context.l10n.placeholderComingSoon)],
                ),
              ),
            ),
          ],
        ),
      );
}

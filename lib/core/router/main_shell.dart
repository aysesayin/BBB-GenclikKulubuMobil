import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_icons.dart';

/// Alt navigasyonlu kabuk: Keşfet · Fırsatlar · (Kartım) · BUAN · Profil.
/// Ortadaki Kartım butonu yükseltilmiş mor daire.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _go(int i) {
    Haptics.selection();
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: AppTabBar(index: shell.currentIndex, onTap: _go),
      );
}

class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 12.0);
    final items = [
      (AppIcons.compass, l.tabExplore, l.tabExplore),
      (AppIcons.tag, l.tabOpportunities, l.tabOpportunities),
      (AppIcons.qr, l.tabCard, l.tabCardSemantics),
      (AppIcons.buanTab, l.tabBuan, l.tabBuan),
      (AppIcons.user, l.tabProfile, l.tabProfile),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l.mainNavLabel,
      child: Container(
        height: 66 + bottom,
        padding: EdgeInsets.fromLTRB(8, 8, 8, bottom),
        decoration: BoxDecoration(color: p.sf, border: Border(top: BorderSide(color: p.line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: i == 2
                    ? _CenterItem(icon: items[i].$1, label: items[i].$2, semantics: items[i].$3, active: index == i, onTap: () => onTap(i))
                    : _Item(icon: items[i].$1, label: items[i].$2, semantics: items[i].$3, active: index == i, onTap: () => onTap(i)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, required this.semantics, required this.active, required this.onTap});

  final String icon, label, semantics;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = active ? p.teal : p.mut;
    return Semantics(
      button: true,
      selected: active,
      label: semantics,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: AppDurations.fast,
                width: 52,
                height: 30,
                decoration: BoxDecoration(color: active ? p.tealS : Colors.transparent, borderRadius: BorderRadius.circular(15)),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 22, color: c),
              ),
              const SizedBox(height: 3),
              Text(label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: AppTypography.body(11, weight: FontWeight.w800, color: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterItem extends StatelessWidget {
  const _CenterItem({required this.icon, required this.label, required this.semantics, required this.active, required this.onTap});

  final String icon, label, semantics;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: active,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: OverflowBox(
          maxHeight: 96,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: p.buanFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.sf, width: 4),
                  boxShadow: [BoxShadow(color: p.buanShadow.withValues(alpha: .4), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 26, color: p.onBuan),
              ),
              const SizedBox(height: 4),
              Text(label, maxLines: 1, style: AppTypography.body(11, weight: FontWeight.w800, color: active ? p.pur : p.mut)),
            ],
          ),
        ),
      ),
    );
  }
}

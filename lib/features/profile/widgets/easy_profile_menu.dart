import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'profile_menu.dart';

/// Kolay Mod menüsü: en fazla 5 büyük satır ([primary]); kalanlar ([secondary]) "Daha fazla"
/// çerçeveli butonuna dokununca aynı boyutta ikinci bir kart olarak açılır.
class EasyProfileMenu extends StatefulWidget {
  const EasyProfileMenu({super.key, required this.label, required this.primary, required this.secondary});

  final String label;
  final List<ProfileMenuItem> primary, secondary;

  @override
  State<EasyProfileMenu> createState() => _EasyProfileMenuState();
}

class _EasyProfileMenuState extends State<EasyProfileMenu> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final primary = widget.primary.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileMenu(label: widget.label, items: primary, large: true, margin: const EdgeInsets.fromLTRB(20, 20, 20, 16)),
        if (widget.secondary.isNotEmpty && !_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: AppButton.outline(
              label: l.commonSeeMore,
              size: AppButtonSize.large,
              icon: AppIcons.chevronDown,
              onPressed: () => setState(() => _expanded = true),
            ),
          ),
        if (_expanded)
          ProfileMenu(label: l.commonSeeMore, items: widget.secondary, large: true, margin: const EdgeInsets.fromLTRB(20, 0, 20, 28)),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'search_suggestions.dart';

/// Sonuç yok: maskot + "Sonuç yok" · "Bunu mu demek istedin: X?" (yakın eşleşme varsa) · popüler etiketler.
class SearchEmptyResults extends StatelessWidget {
  const SearchEmptyResults({super.key, required this.query, required this.suggestion, required this.popular, required this.onPick});

  final String query;
  final String? suggestion;
  final List<String> popular;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return ListView(
      padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        EmptyState(title: l.searchNoResultTitle, message: l.searchNoResultMessage(query)),
        if (suggestion case final s?)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                Text(l.searchDidYouMean, textAlign: TextAlign.center, style: AppTypography.body(14, weight: FontWeight.w800, color: p.mut)),
                const SizedBox(height: 8),
                AppButton.outline(
                  label: s,
                  icon: AppIcons.search,
                  expand: false,
                  semanticLabel: l.searchDidYouMeanSemantics(s),
                  onPressed: () {
                    Haptics.selection();
                    onPick(s);
                  },
                ),
              ],
            ),
          ),
        if (popular.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(l.searchPopularTitle, style: AppTypography.display(19, color: p.ink))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (var i = 0; i < popular.length; i++) SearchTagChip(label: popular[i], index: i, onTap: () => onPick(popular[i]))],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

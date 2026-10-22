import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../view_model/search_view_model.dart';

/// Sorgu boşken: son aramalar (silinebilir) + popüler etiketler.
class SearchSuggestions extends StatelessWidget {
  const SearchSuggestions({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<SearchViewModel>();
    final title = AppTypography.display(19, color: p.ink);
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.paddingOf(context).bottom),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (vm.recent.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(l.searchRecentTitle, style: title)),
              ),
              TextButton(
                onPressed: vm.clearRecent,
                style: TextButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: p.teal),
                child: Text(
                  l.searchRecentClear,
                  style: AppTypography.body(14, weight: FontWeight.w900, color: p.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final q in vm.recent) _RecentRow(query: q, onTap: () => onPick(q), onRemove: () => vm.removeRecent(q)),
          const SizedBox(height: 22),
        ],
        if (vm.popular.isNotEmpty) ...[
          Semantics(header: true, child: Text(l.searchPopularTitle, style: title)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (var i = 0; i < vm.popular.length; i++) SearchTagChip(label: vm.popular[i], index: i, onTap: () => onPick(vm.popular[i]))],
          ),
        ],
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.query, required this.onTap, required this.onRemove});

  final String query;
  final VoidCallback onTap, onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.clock, size: 20, color: p.mut),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              button: true,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  height: 48,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(16, color: p.ink),
                  ),
                ),
              ),
            ),
          ),
          AppIconButton(
            icon: AppIcons.close,
            semanticLabel: '${context.l10n.searchRecentRemove}: $query',
            color: p.mut,
            iconSize: 16,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Sticker etiket: pastel zemin, 2 px ink çerçeve, hafif eğim.
class SearchTagChip extends StatelessWidget {
  const SearchTagChip({super.key, required this.label, required this.index, required this.onTap});

  final String label;
  final int index;
  final VoidCallback onTap;

  static const _tilt = [-2.0, 1.0, -1.0, 2.0, 0.0];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tones = [p.tile2, p.tile1, p.tile6, p.tile3, p.tile4, p.tile5];
    final text = context.l10n.searchTag(label);
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: Transform.rotate(
          angle: _tilt[index % _tilt.length] * 3.1415926535 / 180,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: tones[index % tones.length],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.onTile, width: 2),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(text, style: AppTypography.body(14, weight: FontWeight.w900, color: p.onTile)),
            ),
          ),
        ),
      ),
    );
  }
}

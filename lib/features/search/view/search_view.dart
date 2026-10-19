import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/search_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/search_view_model.dart';
import '../widgets/search_results.dart';
import '../widgets/search_suggestions.dart';

/// B2 · Arama (tam ekran).
class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => SearchViewModel(sl<SearchRepository>())..init(), child: const _Body());
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Etiket / son aramaya dokunma: alanı doldurur ve hemen arar.
  void _pick(String q) {
    _controller.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
    FocusScope.of(context).unfocus();
    context.read<SearchViewModel>().submit(q);
  }

  void _clear() {
    _controller.clear();
    context.read<SearchViewModel>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasQuery = context.select<SearchViewModel, bool>((vm) => vm.hasQuery);
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          _SearchBar(controller: _controller, hasQuery: hasQuery, onClear: _clear),
          Expanded(child: hasQuery ? const SearchResultsPane() : SearchSuggestions(onPick: _pick)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.hasQuery, required this.onClear});

  final TextEditingController controller;
  final bool hasQuery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.read<SearchViewModel>();
    return Padding(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 16, 8),
      child: Row(
        children: [
          AppIconButton(icon: AppIcons.back, semanticLabel: l.commonBack, iconSize: 24, onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
              decoration: BoxDecoration(
                color: p.sf,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: p.teal, width: 2),
              ),
              child: Row(
                children: [
                  AppIcon(AppIcons.search, size: 20, color: p.mut),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      label: l.searchFieldLabel,
                      textField: true,
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: vm.onQueryChanged,
                        onSubmitted: vm.submit,
                        cursorColor: p.teal,
                        style: AppTypography.body(16, color: p.ink),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: l.searchFieldHint,
                          hintStyle: AppTypography.body(16, color: p.mut),
                        ),
                      ),
                    ),
                  ),
                  if (hasQuery)
                    Semantics(
                      button: true,
                      label: l.searchClearField,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onClear,
                        child: SizedBox.square(
                          dimension: 44,
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: p.sf2, shape: BoxShape.circle),
                              child: AppIcon(AppIcons.close, size: 16, color: p.ink, strokeWidth: 2.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

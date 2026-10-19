import 'package:flutter/material.dart';

import '../widgets/state_views.dart';
import 'view_state.dart';

/// [ViewState]'i 4 durum kalıbına çevirir.
///
/// - loading (ilk yükleme) → [skeleton]
/// - empty → [empty] (verilmezse boş kutu)
/// - error → önbellek varsa içerik + [OfflineBanner], yoksa [ErrorStateView]
/// - success → [builder] (fromCache ise üstte çevrimdışı şeridi)
class ViewStateBuilder<T> extends StatelessWidget {
  const ViewStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    required this.skeleton,
    required this.onRetry,
    this.empty,
    this.errorSecondaryLabel,
    this.onErrorSecondary,
  });

  final ViewState<T> state;
  final Widget Function(BuildContext context, T data, {required bool offline}) builder;
  final WidgetBuilder skeleton;
  final Future<void> Function() onRetry;
  final WidgetBuilder? empty;
  final String? errorSecondaryLabel;
  final VoidCallback? onErrorSecondary;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: KeyedSubtree(key: ValueKey(state.runtimeType), child: _body(context)),
      );

  Widget _body(BuildContext context) => switch (state) {
        ViewIdle<T>() => skeleton(context),
        ViewLoading<T>(:final previous) => previous == null ? skeleton(context) : builder(context, previous, offline: false),
        ViewEmpty<T>() => empty?.call(context) ?? const SizedBox.shrink(),
        ViewSuccess<T>(:final data, :final fromCache) => builder(context, data, offline: fromCache),
        ViewError<T>(:final cached, :final error) => cached != null
            ? builder(context, cached, offline: true)
            : ErrorStateView(error: error, onRetry: onRetry, secondaryLabel: errorSecondaryLabel, onSecondary: onErrorSecondary),
      };
}

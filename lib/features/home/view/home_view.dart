import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/view_state.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_feed.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/home_view_model.dart';
import '../widgets/home_content.dart';
import '../widgets/home_skeleton.dart';

/// B1 · Keşfet (ana sekme).
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => HomeViewModel(sl<HomeRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final state = vm.state;
    final Widget child = switch (state) {
      ViewIdle() || ViewEmpty() => const HomeSkeleton(),
      ViewLoading(:final previous?) => HomeContent(feed: previous, greeting: vm.greeting, offline: false, onRefresh: vm.refresh),
      ViewLoading() => switch (vm.retryingFrom) {
        final e? => _HomeError(state: e, onRetry: vm.refresh),
        null => const HomeSkeleton(),
      },
      ViewSuccess(:final data, :final fromCache) => HomeContent(
        feed: data,
        greeting: vm.greeting,
        offline: fromCache,
        onRefresh: vm.refresh,
      ),
      ViewError(:final cached?) => HomeContent(feed: cached, greeting: vm.greeting, offline: true, onRefresh: vm.refresh),
      final ViewError<HomeFeed> e => _HomeError(state: e, onRetry: vm.refresh),
    };
    final key = switch (child) {
      HomeContent() => 'content',
      HomeSkeleton() => 'skeleton',
      _ => 'error',
    };
    return AnimatedSwitcher(
      duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }
}

/// S3 · Çevrimdışı / hata (önbellek yok): üst şerit + şaşkın maskot + "Tekrar dene" + "Kartımı göster".
class _HomeError extends StatelessWidget {
  const _HomeError({required this.state, required this.onRetry});

  final ViewError<HomeFeed> state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: context.palette.bg,
      child: Column(
        children: [
          if (state.isOffline) OfflineBanner(margin: EdgeInsets.fromLTRB(16, pad.top + 4, 16, 0)) else SizedBox(height: pad.top),
          Expanded(
            child: ErrorStateView(
              error: state.error,
              onRetry: onRetry,
              secondaryLabel: context.l10n.offlineShowCard,
              onSecondary: () => context.go(Routes.card),
            ),
          ),
          SizedBox(height: AppSpacing.tabBarHeight + pad.bottom),
        ],
      ),
    );
  }
}

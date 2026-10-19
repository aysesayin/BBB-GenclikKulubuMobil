import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../notifications/view/notifications_view.dart';
import '../search/view/search_view.dart';
import '../stories/view/story_view.dart';

/// B · Keşfet tam ekran rotaları (alt navigasyonsuz).
final List<RouteBase> homeRootRoutes = [
  GoRoute(path: Routes.search, builder: (_, _) => const SearchView()),
  GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsView()),
  GoRoute(
    path: '/hikaye/:id',
    pageBuilder: (_, state) => MaterialPage(
      key: state.pageKey,
      fullscreenDialog: true,
      child: StoryView(storyId: state.pathParameters['id'] ?? ''),
    ),
  ),
];

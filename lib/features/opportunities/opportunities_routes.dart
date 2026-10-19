import 'package:go_router/go_router.dart';

import 'view/claimed_view.dart';
import 'view/my_opportunities_view.dart';
import 'view/opportunity_detail_view.dart';

/// Fırsatlar sekmesi içindeki alt rotalar (alt navigasyon görünür): `/firsatlar/cuzdan`.
final List<RouteBase> opportunitiesBranchRoutes = [GoRoute(path: 'cuzdan', builder: (_, _) => const MyOpportunitiesView())];

/// Tam ekran rotalar (kök navigator).
final List<RouteBase> opportunitiesRootRoutes = [
  GoRoute(
    path: '/firsat/:id',
    builder: (_, s) => OpportunityDetailView(key: s.pageKey, id: s.pathParameters['id'] ?? ''),
  ),
  GoRoute(
    path: '/firsat/:id/yakalandi',
    builder: (_, s) => ClaimedView(key: s.pageKey, id: s.pathParameters['id'] ?? '', extra: ClaimedExtra.from(s.extra)),
  ),
];

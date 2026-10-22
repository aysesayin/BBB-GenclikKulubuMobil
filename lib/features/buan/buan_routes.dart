import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/router/navigator_keys.dart';
import 'badges/view/badges_view.dart';
import 'history/view/history_view.dart';
import 'league/view/league_view.dart';
import 'market/view/market_view.dart';
import 'market/view/reward_detail_view.dart';
import 'tasks/detail/view/task_detail_view.dart';

/// BUAN sekmesi alt rotaları (`/buan/...`). Ödül ve görev detayı tam ekran (kök navigator).
final List<RouteBase> buanBranchRoutes = [
  GoRoute(path: 'pazar', builder: (_, _) => const MarketView()),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: 'pazar/:id',
    builder: (_, state) => RewardDetailView(rewardId: state.param('id')),
  ),
  GoRoute(path: 'lig', builder: (_, _) => const LeagueView()),
  GoRoute(path: 'rozetler', builder: (_, _) => const BadgesView()),
  GoRoute(path: 'gecmis', builder: (_, _) => const HistoryView()),
  // Genel görev detayı (Takip Et, Gönül Dostu, BİKO, Fikrin ile Kazan, Fırsat Kullan…) — tam ekran.
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: 'gorev/:id',
    builder: (_, state) => TaskDetailView(taskId: state.param('id')),
  ),
];

import 'package:go_router/go_router.dart';

import 'view/games_view.dart';

/// F · Oyunlar — Keşfet sekmesinin alt rotası (`/kesfet/oyunlar`, sekme çubuğu görünür).
final List<RouteBase> gamesKesfetRoutes = [GoRoute(path: 'oyunlar', builder: (_, _) => const GamesView())];

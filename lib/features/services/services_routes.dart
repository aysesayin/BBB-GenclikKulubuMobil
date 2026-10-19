import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import 'applications/view/applications_view.dart';
import 'cart/view/cart_view.dart';
import 'pool/view/pools_view.dart';
import 'session/view/session_view.dart';
import 'sports_school/view/sports_school_view.dart';

/// Keşfet sekmesi içindeki alt rotalar (alt navigasyon görünür).
final List<RouteBase> servicesKesfetRoutes = [
  GoRoute(path: 'havuzlar', builder: (_, _) => const PoolsView()),
  GoRoute(path: 'spor-okullari', builder: (_, _) => const SportsSchoolView()),
];

/// Profil sekmesi içindeki alt rotalar.
final List<RouteBase> servicesProfileRoutes = [
  GoRoute(path: 'basvurularim', builder: (_, _) => const ApplicationsView()),
];

/// Tam ekran rotalar.
final List<RouteBase> servicesRootRoutes = [
  GoRoute(
    path: '/seans/:itemId',
    builder: (_, s) => SessionView(itemId: s.pathParameters['itemId'] ?? ''),
  ),
  GoRoute(path: Routes.cart, builder: (_, _) => const CartView()),
];

import 'package:go_router/go_router.dart';

import '../../core/router/navigator_keys.dart';
import 'children/view/children_view.dart';
import 'coupons/view/coupons_view.dart';
import 'discounts/view/discounts_view.dart';
import 'settings/view/settings_view.dart';
import 'support/view/support_view.dart';

/// Profil sekmesinin alt rotaları. Kuponlar sekme içinde (alt navigasyon görünür),
/// diğerleri kök navigator'da tam ekran açılır.
final List<RouteBase> profileBranchRoutes = [
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'ayarlar', builder: (_, _) => const SettingsView()),
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'indirim', builder: (_, _) => const DiscountsView()),
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'cocuk', builder: (_, _) => const ChildrenView()),
  GoRoute(path: 'kuponlar', builder: (_, _) => const CouponsView()),
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'destek', builder: (_, _) => const SupportView()),
];

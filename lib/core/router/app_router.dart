import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/buan/buan_routes.dart';
import '../../features/buan/tasks/tasks_routes.dart';
import '../../features/buan/view/buan_view.dart';
import '../../features/card_qr/card_routes.dart';
import '../../features/card_qr/view/card_view.dart';
import '../../features/events/events_routes.dart';
import '../../features/games/games_routes.dart';
import '../../features/home/home_routes.dart';
import '../../features/home/view/home_view.dart';
import '../../features/onboarding/onboarding_routes.dart';
import '../../features/opportunities/opportunities_routes.dart';
import '../../features/opportunities/view/opportunity_list_view.dart';
import '../../features/profile/profile_routes.dart';
import '../../features/profile/view/profile_view.dart';
import '../../features/services/services_routes.dart';
import '../session/session_controller.dart';
import 'main_shell.dart';
import 'navigator_keys.dart';
import 'routes.dart';

/// Uygulama yönlendiricisi. Her özellik kendi `*_routes.dart` dosyasında rota
/// listesi yayınlar; burada yalnız iskelet (kabuk + sekmeler + guard) kurulur.
///
/// Sekme içi alt rotalar alt navigasyonu gösterir; tam ekran olması gereken alt
/// rotalar `parentNavigatorKey: rootNavigatorKey` kullanır.
GoRouter createRouter(SessionController session) => GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: Routes.splash,
      refreshListenable: session,
      redirect: (context, state) => _guard(session, state),
      routes: [
        GoRoute(path: '/', redirect: (_, _) => Routes.home),
        GoRoute(
          path: Routes.inviteDeepLink,
          redirect: (_, s) => Routes.registerWithReferral(s.pathParameters['code'] ?? ''),
        ),
        GoRoute(path: '/firsat', redirect: (_, _) => Routes.opportunities),
        ...onboardingRoutes,
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, _) => const HomeView(),
                routes: [...eventsKesfetRoutes, ...servicesKesfetRoutes, ...gamesKesfetRoutes],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.opportunities,
                builder: (_, _) => const OpportunityListView(),
                routes: opportunitiesBranchRoutes,
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: Routes.card, builder: (_, _) => const CardView()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.buan,
                builder: (_, _) => const BuanView(),
                routes: [...buanBranchRoutes, ...buanTaskBranchRoutes],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileView(),
                routes: [...profileBranchRoutes, ...servicesProfileRoutes],
              ),
            ]),
          ],
        ),
        ...homeRootRoutes,
        ...opportunitiesRootRoutes,
        ...cardRootRoutes,
        ...eventsRootRoutes,
        ...servicesRootRoutes,
      ],
    );

String? _guard(SessionController session, GoRouterState state) {
  final loc = state.matchedLocation;
  if (session.status == SessionStatus.unknown) return null; // splash oturumu çözer
  if (session.isGuest && Routes.isProtected(loc)) {
    return Uri(path: Routes.welcome, queryParameters: {'from': state.uri.toString()}).toString();
  }
  return null;
}

/// Rota parametresi okuma kısayolu.
extension GoRouterStateX on GoRouterState {
  String param(String name) => pathParameters[name] ?? '';
}

/// Testlerde/özelliklerde yönlendiriciye erişim.
GoRouter routerOf(BuildContext context) => GoRouter.of(context);

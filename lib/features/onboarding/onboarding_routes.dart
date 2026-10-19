import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../auth/view/login_view.dart';
import '../auth/view/register_view.dart';
import '../splash/view/splash_view.dart';
import 'view/interests_view.dart';
import 'view/permissions_view.dart';
import 'view/story_view.dart';
import 'view/summit_view.dart';
import 'view/welcome_view.dart';

/// A · Giriş akışı rotaları (alt navigasyon yok). Ekranlar arası geçiş kısa
/// fade: blob'lar ve coin sahneler arasında kesintisiz görünür.
final List<RouteBase> onboardingRoutes = [
  _route(Routes.splash, (_) => const SplashView()),
  _route(Routes.onboarding, (_) => const StoryView()),
  _route(Routes.welcome, (s) => WelcomeView(from: s.uri.queryParameters['from'])),
  _route(Routes.interests, (_) => const InterestsView()),
  _route(Routes.register, (s) => RegisterView(referralCode: s.uri.queryParameters['ref'])),
  _route(Routes.login, (s) => LoginView(from: s.uri.queryParameters['from'])),
  _route(Routes.summit, (_) => const SummitView()),
  _route(Routes.permissions, (_) => const PermissionsView()),
];

GoRoute _route(String path, Widget Function(GoRouterState state) build) => GoRoute(
      path: path,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        name: path,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        child: build(state),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );

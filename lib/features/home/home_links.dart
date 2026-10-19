import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/home/app_link.dart';

/// Panel bağlantısını ([AppLink]) uygulama rotasına çevirir. Bilinmeyen tür → null.
String? routeForLink(AppLink link) {
  final id = link.id;
  final hasId = id != null && id.isNotEmpty;
  return switch (link.type) {
    'opportunity' => hasId ? Routes.opportunity(id) : Routes.opportunities,
    'opportunities' => Routes.opportunities,
    'event' => hasId ? Routes.event(id) : Routes.events,
    'events' => Routes.events,
    'place' => hasId ? Routes.place(id) : Routes.map,
    'map' => Routes.map,
    'pools' => Routes.pools,
    'sportsSchools' || 'tennis' => Routes.sportsSchools,
    'games' => Routes.games,
    'quiz' || 'survey' => Routes.quiz,
    'steps' => Routes.steps,
    'watchEarn' => Routes.watchEarn,
    'dailySpin' => Routes.dailySpin,
    'invite' => Routes.invite,
    'photoReport' => Routes.photoReport,
    'reward' => hasId ? Routes.reward(id) : Routes.market,
    'market' => Routes.market,
    'buan' => Routes.buan,
    'league' => Routes.league,
    'badges' => Routes.badges,
    'history' => Routes.history,
    'story' => hasId ? Routes.story(id) : null,
    'card' => Routes.card,
    'applications' => Routes.applications,
    'profile' => Routes.profile,
    'notifications' => Routes.notifications,
    'search' => Routes.search,
    _ => null,
  };
}

const _tabRoots = {Routes.home, Routes.opportunities, Routes.card, Routes.buan, Routes.profile};

/// Alt navigasyon sekmesi kökü mü (go ile açılır)?
bool isTabRoot(String route) => _tabRoots.contains(route);

/// Sekme köklerine `go` (sekme değişir), diğer her yere `push` (geri dönülebilir).
void openRoute(BuildContext context, String route) {
  if (isTabRoot(route)) {
    context.go(route);
  } else {
    context.push(route);
  }
}

/// [AppLink]'i açar; eşlenemeyen bağlantı sessizce yok sayılır.
void openLink(BuildContext context, AppLink? link) {
  final route = link == null ? null : routeForLink(link);
  if (route != null) openRoute(context, route);
}

/// API'deki 1–6 karo tonunu palete çevirir.
Color toneColor(AppPalette p, int tone) => p.tiles[(tone - 1).clamp(0, 5)];

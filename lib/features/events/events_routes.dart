import 'package:go_router/go_router.dart';

import '../../data/models/map/map_pin.dart';
import '../map/view/map_view.dart';
import '../places/view/place_detail_view.dart';
import 'view/event_detail_view.dart';
import 'view/event_list_view.dart';

/// G · Keşfet sekmesi içindeki alt rotalar (alt navigasyon görünür):
/// `/kesfet/etkinlikler`, `/kesfet/harita?layer=places|events|opportunities&cat=<kategori>`.
final List<RouteBase> eventsKesfetRoutes = [
  GoRoute(path: 'etkinlikler', builder: (_, _) => const EventListView()),
  GoRoute(
    path: 'harita',
    builder: (_, state) => MapView(
      initialLayer: MapLayer.tryParse(state.uri.queryParameters['layer']),
      initialCategory: state.uri.queryParameters['cat'],
    ),
  ),
];

/// Tam ekran rotalar: `/etkinlik/:id`, `/yer/:id` (yer ya da tesis kimliği).
final List<RouteBase> eventsRootRoutes = [
  GoRoute(path: '/etkinlik/:id', builder: (_, state) => EventDetailView(id: state.pathParameters['id'] ?? '')),
  GoRoute(path: '/yer/:id', builder: (_, state) => PlaceDetailView(id: state.pathParameters['id'] ?? '')),
];

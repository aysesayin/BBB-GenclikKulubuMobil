import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/map/map_pin.dart';
import '../utils/pin_clustering.dart';
import 'map_icons.dart';
import 'map_markers.dart';

/// flutter_map + OSM karoları + kümelenmiş pinler + kullanıcı konumu.
/// Koyu temada karolar ters çevrilip palet zeminiyle karartılır (HaritaKoyu).
class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.controller,
    required this.pins,
    required this.selectedId,
    required this.userLocation,
    required this.colorOf,
    required this.onPin,
    required this.onBackgroundTap,
    required this.onCameraChanged,
    required this.onReady,
    this.initialCenter = bursaCenter,
  });

  final MapController controller;
  final List<MapPin> pins;
  final String? selectedId;
  final LatLng? userLocation;
  final Color Function(MapPin) colorOf;
  final ValueChanged<MapPin> onPin;
  final VoidCallback onBackgroundTap;
  final ValueChanged<MapCamera> onCameraChanged;
  final VoidCallback onReady;
  final LatLng initialCenter;

  static const _maxZoom = 18.0;

  /// Koyu mod: renkleri ters çevirip tonu 180° döndürür (flutter_map `darkModeTileBuilder` matrisi).
  static const _darkMatrix = <double>[
    0.574, -1.43, -0.144, 0, 255, //
    -0.426, -0.43, -0.144, 0, 255, //
    -0.426, -1.43, 0.856, 0, 255, //
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget tiles = TileLayer(
      urlTemplate: ApiConfig.mapTileUrlTemplate,
      userAgentPackageName: ApiConfig.mapUserAgentPackage,
      maxZoom: _maxZoom,
    );
    if (p.isDark) tiles = ColorFiltered(colorFilter: const ColorFilter.matrix(_darkMatrix), child: tiles);
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 13,
        minZoom: 8,
        maxZoom: _maxZoom,
        backgroundColor: p.mapLand,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        onTap: (_, _) => onBackgroundTap(),
        onPositionChanged: (camera, _) => onCameraChanged(camera),
        onMapReady: onReady,
      ),
      children: [
        tiles,
        // Karoları paletle uyumlu hale getiren ince örtü (koyuda belirgin karartma).
        IgnorePointer(child: ColoredBox(color: p.mapLand.withValues(alpha: p.isDark ? .35 : .12), child: const SizedBox.expand())),
        if (userLocation != null)
          MarkerLayer(markers: [Marker(point: userLocation!, width: 44, height: 44, child: const Center(child: UserLocationDot()))]),
        _ClusteredPins(pins: pins, selectedId: selectedId, colorOf: colorOf, onPin: onPin, controller: controller),
      ],
    );
  }
}

class _ClusteredPins extends StatelessWidget {
  const _ClusteredPins({required this.pins, required this.selectedId, required this.colorOf, required this.onPin, required this.controller});

  final List<MapPin> pins;
  final String? selectedId;
  final Color Function(MapPin) colorOf;
  final ValueChanged<MapPin> onPin;
  final MapController controller;

  LatLng _pos(MapPin p) => LatLng(p.lat, p.lng);

  void _zoomInto(BuildContext context, PinCluster<MapPin> c) {
    final camera = MapCamera.of(context);
    final points = c.positions(_pos);
    final sameSpot = points.every((pt) => pt == points.first);
    if (sameSpot || camera.zoom >= 16) {
      onPin(c.first); // aynı noktadaki pinler açılamaz → ilkini önizle
      return;
    }
    controller.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(96), maxZoom: 17));
  }

  @override
  Widget build(BuildContext context) {
    final zoom = MapCamera.of(context).zoom.floorToDouble();
    final selected = pins.where((p) => p.id == selectedId).toList();
    final others = pins.where((p) => p.id != selectedId);
    final clusters = clusterByGrid(others, position: _pos, zoom: zoom);
    final markers = <Marker>[
      for (final c in clusters)
        if (c.isCluster)
          Marker(
            point: c.center,
            width: 56,
            height: 56,
            child: Center(child: ClusterBubble(count: c.count, onTap: () => _zoomInto(context, c))),
          )
        else
          _pinMarker(c.first, selected: false),
      // Seçili pin hiç kümelenmez ve en üstte çizilir.
      for (final s in selected) _pinMarker(s, selected: true),
    ];
    return MarkerLayer(markers: markers);
  }

  Marker _pinMarker(MapPin pin, {required bool selected}) => Marker(
        key: ValueKey(pin.id),
        point: _pos(pin),
        width: kPinBox,
        height: kPinBox,
        alignment: Alignment.topCenter,
        child: TeardropPin(
          color: colorOf(pin),
          icon: MapIcons.forKey(pin.icon),
          label: pin.name,
          selected: selected,
          onTap: () => onPin(pin),
        ),
      );
}

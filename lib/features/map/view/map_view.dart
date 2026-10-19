import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/view_state.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/map/map_pin.dart';
import '../../../data/repositories/map_repository.dart';
import '../../../l10n/l10n.dart';
import '../../events/widgets/discover_palette.dart';
import '../../places/utils/directions.dart';
import '../location/location_provider.dart';
import '../view_model/map_view_model.dart';
import '../widgets/map_canvas.dart';
import '../widgets/map_icons.dart';
import '../widgets/map_preview_panel.dart';
import '../widgets/map_top_bar.dart';
import '../widgets/nearby_places_sheet.dart';

/// G3 · Harita (Keşfet sekmesi içinde). `?layer=events&cat=genclik-merkezi` ile açılabilir.
class MapView extends StatelessWidget {
  const MapView({super.key, this.initialLayer, this.initialCategory});

  final MapLayer? initialLayer;
  final String? initialCategory;

  static const _location = GeolocatorLocationProvider();

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        // İlk yükleme harita hazır olunca görünür alanla yapılır (onReady → updateBounds).
        create: (_) => MapViewModel(sl<MapRepository>(), _location, initialLayer: initialLayer, initialCategory: initialCategory),
        child: const _Body(),
      );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _map = MapController();
  Timer? _debounce;

  MapViewModel get _vm => context.read<MapViewModel>();

  @override
  void dispose() {
    _debounce?.cancel();
    _map.dispose();
    super.dispose();
  }

  MapBounds _boundsOf(MapCamera c) {
    final b = c.visibleBounds;
    return MapBounds(south: b.south, west: b.west, north: b.north, east: b.east);
  }

  void _onCamera(MapCamera camera) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _vm.updateBounds(_boundsOf(camera));
    });
  }

  Future<void> _locate() async {
    final l = context.l10n;
    final r = await _vm.locate();
    if (!mounted) return;
    if (r.isOk) {
      _map.move(r.position!, math.max(_map.camera.zoom, 14));
      return;
    }
    final settings = r.status == LocationStatus.deniedForever || r.status == LocationStatus.serviceDisabled;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(switch (r.status) {
          LocationStatus.serviceDisabled => l.mapLocationServiceOff,
          LocationStatus.denied || LocationStatus.deniedForever => l.mapLocationDenied,
          _ => l.mapLocationError,
        }),
        action: settings ? SnackBarAction(label: l.mapOpenSettings, onPressed: _vm.openLocationSettings) : null,
      ));
  }

  void _openDetail(MapPin pin) {
    final id = pin.targetId;
    if (id == null) return;
    context.push(switch (pin.layer) {
      MapLayer.places => Routes.place(id),
      MapLayer.events => Routes.event(id),
      MapLayer.opportunities => Routes.opportunity(id),
    });
  }

  Color _colorOf(MapPin pin) {
    final p = context.palette;
    final fallback = switch (pin.layer) {
      MapLayer.places => p.primary,
      MapLayer.events => p.primary,
      MapLayer.opportunities => p.hotFill,
    };
    return paletteColor(p, pin.color ?? _vm.categoryOf(pin)?.color, fallback: fallback);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<MapViewModel>();
    final selected = vm.selectedPin;
    final media = MediaQuery.of(context);
    final bottomInset = math.max(media.padding.bottom, AppSpacing.tabBarHeight);
    return Scaffold(
      backgroundColor: p.mapLand,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapCanvas(
              controller: _map,
              pins: vm.visiblePins,
              selectedId: selected?.id,
              userLocation: vm.userLocation,
              colorOf: _colorOf,
              onPin: (pin) => vm.selectPin(pin.id),
              onBackgroundTap: () => vm.selectPin(null),
              onCameraChanged: _onCamera,
              onReady: () => vm.updateBounds(_boundsOf(_map.camera)),
            ),
          ),
          Positioned(
            top: media.padding.top + 8,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MapTopBar(
                  layer: vm.layer,
                  categories: vm.categories,
                  categoryId: vm.categoryId,
                  onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
                  onNearby: () => NearbyPlacesSheet.show(context, knownLocation: vm.userLocation, location: MapView._location),
                  onLayer: vm.setLayer,
                  onCategory: vm.toggleCategory,
                ),
                _StatusPill(vm: vm),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text(l.mapAttribution, style: AppTypography.body(10, weight: FontWeight.w700, color: p.mut))),
                      vm.locating
                          ? SizedBox.square(dimension: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 3, color: p.teal)))
                          : AppIconButton(
                              icon: MapIcons.navigate,
                              semanticLabel: l.mapGoToMyLocation,
                              onPressed: _locate,
                              size: 48,
                              background: p.sf,
                              color: p.teal,
                              shadow: true,
                            ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: context.reduceMotion ? Duration.zero : AppDurations.sheet,
                  transitionBuilder: (child, a) => SizeTransition(sizeFactor: a, axisAlignment: 1, child: child),
                  child: selected == null
                      ? const SizedBox(width: double.infinity)
                      : MapPreviewPanel(
                          key: ValueKey(selected.id),
                          pin: selected,
                          onDetail: selected.targetId == null ? null : () => _openDetail(selected),
                          onDirections: () => openDirections(context, directionsUri(selected.lat, selected.lng), failureMessage: l.mapDirectionsFailed),
                          onClose: () => vm.selectPin(null),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Üst çubuğun altındaki küçük durum bildirimi: yükleniyor / hata / boş katman.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.vm});

  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final state = vm.state;
    final Widget? child = switch (state) {
      ViewError(:final error, :final cached) when cached == null => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(errorMessageOf(context, error), style: AppTypography.body(13, weight: FontWeight.w800, color: p.ink))),
            TextButton(onPressed: vm.load, child: Text(l.commonRetry, style: AppTypography.body(13, weight: FontWeight.w900, color: p.teal))),
          ],
        ),
      ViewError() => const OfflineBanner(margin: EdgeInsets.zero),
      ViewSuccess() when vm.visiblePins.isEmpty => Text(l.mapLayerEmpty, style: AppTypography.body(13, weight: FontWeight.w800, color: p.ink)),
      ViewLoading(:final previous) when previous == null => SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: p.teal, semanticsLabel: l.commonLoading),
        ),
      _ => null,
    };
    if (child == null) return const SizedBox.shrink();
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 2, 16, 0),
        padding: child is OfflineBanner ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(20), boxShadow: p.cardShadow),
        child: Semantics(liveRegion: true, child: child),
      ),
    );
  }
}

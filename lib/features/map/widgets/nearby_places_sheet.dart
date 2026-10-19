import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/place_repository.dart';
import '../../../l10n/l10n.dart';
import '../../events/widgets/discover_palette.dart';
import '../../places/utils/directions.dart';
import '../location/location_provider.dart';
import '../view_model/nearby_places_view_model.dart';
import 'map_icons.dart';

/// "Yakınımdaki yerler" alt sayfası. Konum izni yoksa Bursa merkezine göre sıralar ve nedenini söyler.
abstract final class NearbyPlacesSheet {
  static Future<void> show(BuildContext context, {LatLng? knownLocation, required LocationProvider location}) =>
      AppSheet.show<void>(
        context,
        scrollable: false,
        builder: (_) => ChangeNotifierProvider(
          create: (_) => NearbyPlacesViewModel(sl<PlaceRepository>(), location, knownLocation: knownLocation)..load(),
          child: const _SheetBody(),
        ),
      );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<NearbyPlacesViewModel>();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l.mapNearbyPlaces, style: AppTypography.display(24, color: p.ink))),
          if (vm.usingFallback) ...[const SizedBox(height: 10), _FallbackNote(status: vm.locationStatus!, onSettings: vm.openLocationSettings)],
          const SizedBox(height: 8),
          Expanded(
            child: ViewStateBuilder<List<NearbyPlace>>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => Shimmer(
                child: Column(children: [for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(top: 12), child: SkeletonBox(height: 56, radius: 16))]),
              ),
              empty: (_) => EmptyState(title: l.mapNearbyEmptyTitle, message: l.mapNearbyEmptyMessage),
              builder: (context, items, {required offline}) => ListView.separated(
                itemCount: items.length,
                padding: const EdgeInsets.only(top: 8),
                separatorBuilder: (_, _) => Divider(color: p.line, height: 1),
                itemBuilder: (context, i) => _NearbyTile(item: items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({required this.item});

  final NearbyPlace item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final place = item.place;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          router.push(Routes.place(place.id));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              IconTile(icon: MapIcons.forKey(place.icon), color: paletteColor(p, place.tone), size: 48, radius: 14, iconSize: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink)),
                    Text(
                      [place.categoryLabel, place.statusLabel].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(13, color: place.openNow ? p.grnT : p.mut),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(formatDistance(context, item.distanceMeters), style: AppTypography.number(13, weight: FontWeight.w800, color: p.mut)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackNote extends StatelessWidget {
  const _FallbackNote({required this.status, required this.onSettings});

  final LocationStatus status;
  final Future<bool> Function() onSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final message = switch (status) {
      LocationStatus.serviceDisabled => '${l.mapLocationServiceOff} ${l.mapNearbyFallback}',
      LocationStatus.denied || LocationStatus.deniedForever => l.mapLocationDenied,
      _ => l.mapLocationError,
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(color: p.yelS, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            AppIcon(AppIcons.pin, size: 18, color: p.warningText),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AppTypography.body(13, height: 1.35, color: p.ink))),
            if (status == LocationStatus.deniedForever || status == LocationStatus.serviceDisabled)
              TextButton(onPressed: onSettings, child: Text(l.mapOpenSettings, style: AppTypography.body(13, weight: FontWeight.w900, color: p.teal))),
          ],
        ),
      ),
    );
  }
}

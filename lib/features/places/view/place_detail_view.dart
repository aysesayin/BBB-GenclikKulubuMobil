import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/places/place.dart';
import '../../../data/repositories/place_repository.dart';
import '../../../l10n/l10n.dart';
import '../../events/widgets/event_cover.dart';
import '../utils/directions.dart';
import '../view_model/place_detail_view_model.dart';
import '../widgets/place_gallery.dart';
import '../widgets/place_sections.dart';

/// G4 · Yer / tesis detayı (tam ekran). Gençlik merkezleri ve spor tesisleri de bu ekranı kullanır.
class PlaceDetailView extends StatelessWidget {
  const PlaceDetailView({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => PlaceDetailViewModel(sl<PlaceRepository>(), id)..load(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  void _checkIn(BuildContext context) =>
      AuthGate.guard(context, () => context.push(Routes.qrScan), title: context.l10n.placeCheckInTitle);

  void _openAction(BuildContext context, PlaceAction a) {
    final id = a.targetId;
    switch (a.type) {
      case PlaceActionType.checkin:
        _checkIn(context);
      case PlaceActionType.opportunity when id != null:
        context.push(Routes.opportunity(id));
      case PlaceActionType.event when id != null:
        context.push(Routes.event(id));
      case PlaceActionType.task:
        // TODO(varsayım): Görev detayı rotası yok; BUAN sekmesindeki görev listesine gidilir.
        context.go(Routes.buan);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<PlaceDetailViewModel>();
    final data = vm.state.dataOrNull;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: p.sf,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ViewStateBuilder<PlaceDetail>(
                    state: vm.state,
                    onRetry: vm.load,
                    skeleton: (_) => const _Skeleton(),
                    builder: (context, d, {required offline}) => _Content(place: d, offline: offline, onAction: (a) => _openAction(context, a)),
                  ),
                ),
                Positioned(
                  top: top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      CoverIconButton(
                        icon: AppIcons.back,
                        semanticLabel: l.commonBack,
                        onPressed: () => context.canPop() ? context.pop() : context.go(Routes.map),
                      ),
                      const Spacer(),
                      if (data != null)
                        CoverIconButton(
                          icon: AppIcons.heart,
                          semanticLabel: vm.favorite ? l.placeFavoriteRemove : l.placeFavoriteAdd,
                          color: p.pinkT,
                          fill: vm.favorite ? p.pinkT : null,
                          onPressed: () {
                            Haptics.selection();
                            vm.toggleFavorite();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (data != null)
            StickyBottomBar(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppButton(
                      label: l.placeDirections,
                      variant: AppButtonVariant.outlineInk,
                      size: AppButtonSize.large,
                      onPressed: vm.directions == null
                          ? null
                          : () => openDirections(context, vm.directions, failureMessage: l.placeDirectionsFailed),
                    ),
                  ),
                  if (data.checkInEnabled) ...[
                    const SizedBox(width: 10),
                    Expanded(child: AppButton(label: l.placeCheckIn, onPressed: () => _checkIn(context))),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.place, required this.offline, required this.onAction});

  final PlaceDetail place;
  final bool offline;
  final ValueChanged<PlaceAction> onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.read<PlaceDetailViewModel>();
    final kicker = [place.categoryLabel, place.district].where((s) => s.isNotEmpty).join(' · ');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlaceGallery(images: place.gallery, index: context.select<PlaceDetailViewModel, int>((v) => v.galleryIndex), onChanged: vm.setGalleryIndex),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              decoration: BoxDecoration(color: p.sf, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (offline) const Padding(padding: EdgeInsets.only(bottom: 16), child: OfflineBanner(margin: EdgeInsets.zero)),
                  if (kicker.isNotEmpty) Text(kicker, style: AppTypography.body(13, weight: FontWeight.w900, color: p.pinkT)),
                  const SizedBox(height: 4),
                  Semantics(header: true, child: Text(place.name, style: AppTypography.display(28, height: 1.08, color: p.ink))),
                  if (place.statusLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(place.statusLabel, style: AppTypography.body(13, weight: FontWeight.w800, color: place.openNow ? p.grnT : p.pinkT)),
                  ],
                  if (place.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(place.description, style: AppTypography.body(14, weight: FontWeight.w600, height: 1.55, color: p.mut)),
                  ],
                  if (place.actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    PlaceSection(
                      title: l.placeThingsToDo,
                      gap: 10,
                      child: Column(
                        children: [
                          for (var i = 0; i < place.actions.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            PlaceActionRow(action: place.actions[i], onTap: () => onAction(place.actions[i])),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (place.hours.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    PlaceSection(title: l.placeHoursTitle, child: PlaceHoursTable(hours: place.hours)),
                  ],
                  if (place.amenities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    PlaceSection(title: l.placeAmenitiesTitle, child: PlaceAmenities(amenities: place.amenities)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 280, radius: 0),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(height: 10),
                  SkeletonBox(width: 260, height: 30),
                  SizedBox(height: 16),
                  SkeletonBox(height: 60),
                  SizedBox(height: 16),
                  SkeletonBox(height: 68, radius: 20),
                  SizedBox(height: 10),
                  SkeletonBox(height: 68, radius: 20),
                ],
              ),
            ),
          ],
        ),
      );
}

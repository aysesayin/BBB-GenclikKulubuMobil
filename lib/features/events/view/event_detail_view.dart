import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/events/event_detail.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/event_detail_view_model.dart';
import '../widgets/event_apply_bar.dart';
import '../widgets/event_cover.dart';
import '../widgets/event_format.dart';
import '../widgets/event_info_sections.dart';
import '../widgets/events_icons.dart';

/// G2 · Etkinlik detayı (tam ekran). iOS 393 ve Android 360 düzenleri aynı esnek yerleşimle çalışır.
class EventDetailView extends StatelessWidget {
  const EventDetailView({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => EventDetailViewModel(sl<EventRepository>(), id)..load(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  Future<void> _apply(BuildContext context, EventDetailViewModel vm) async {
    final l = context.l10n;
    final outcome = await vm.apply();
    if (outcome == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (outcome.kind) {
      case EventApplyKind.applied || EventApplyKind.waitlisted:
        Haptics.medium();
        messenger.showSnackBar(SnackBar(content: Text(outcome.message ?? l.eventApplied)));
      case EventApplyKind.failed:
        Haptics.error();
        messenger.showSnackBar(SnackBar(content: Text(errorMessageOf(context, outcome.error!))));
    }
  }

  void _share(BuildContext context, EventDetail e) {
    final text = context.l10n.eventShareText(e.title, ApiEndpoints.eventShareLink(e.id));
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<EventDetailViewModel>();
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
                  child: ViewStateBuilder<EventDetail>(
                    state: vm.state,
                    onRetry: vm.load,
                    skeleton: (_) => const _DetailSkeleton(),
                    builder: (context, e, {required offline}) => _Content(event: e, offline: offline),
                  ),
                ),
                Positioned(
                  top: top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      CoverIconButton(icon: AppIcons.back, semanticLabel: l.commonBack, onPressed: () => context.canPop() ? context.pop() : context.go(Routes.events)),
                      const Spacer(),
                      if (data != null)
                        CoverIconButton(icon: EventIcons.share, iconSize: 20, semanticLabel: l.commonShare, onPressed: () => _share(context, data)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (data != null)
            EventApplyBar(
              cta: vm.cta,
              busy: vm.applying,
              onApply: () => AuthGate.guard(context, () => _apply(context, vm), title: l.eventGuestTitle),
              // TODO(varsayım): Cihaz takvimine ekleme için paket henüz yok; şimdilik bilgi mesajı.
              onCalendar: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l.eventCalendarSoon))),
            ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.event, required this.offline});

  final EventDetail event;
  final bool offline;

  String _age(BuildContext context) {
    final l = context.l10n;
    return switch ((event.ageMin, event.ageMax)) {
      (final int min, final int max) => l.eventAgeRange(min, max),
      (final int min, null) => l.eventAgeMin(min),
      _ => l.eventAgeAll,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final e = event;
    final deadline = e.applyDeadline;
    final placeId = e.placeId;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EventCover(cover: e.cover, icon: e.icon, tone: e.tone, url: e.coverUrl),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              decoration: BoxDecoration(color: p.sf, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (offline) const Padding(padding: EdgeInsets.only(bottom: 16), child: OfflineBanner(margin: EdgeInsets.zero)),
                  EventChips(event: e),
                  const SizedBox(height: 16),
                  Semantics(header: true, child: Text(e.title, style: AppTypography.display(28, height: 1.08, color: p.ink))),
                  const SizedBox(height: 16),
                  EventInfoRow(
                    icon: AppIcons.calendar,
                    title: EventFormat.detailWhen(context, e.startsAt, e.endsAt),
                    subtitle: deadline == null ? null : l.eventApplyDeadline(EventFormat.dayMonth(context, deadline)),
                  ),
                  const SizedBox(height: 12),
                  EventInfoRow(
                    icon: AppIcons.pin,
                    title: e.placeName,
                    subtitle: e.placeNote,
                    semanticLabel: l.eventOpenPlace(e.placeName),
                    onTap: placeId == null ? null : () => context.push(Routes.place(placeId)),
                  ),
                  const SizedBox(height: 12),
                  EventInfoRow(icon: EventIcons.ticket, title: e.price == 0 ? l.eventFree : Fmt.currency(e.price), subtitle: e.priceNote),
                  const SizedBox(height: 12),
                  EventInfoRow(icon: EventIcons.age, title: _age(context), subtitle: e.ageNote),
                  if (e.capacity > 0) ...[const SizedBox(height: 16), EventCapacityBox(event: e)],
                  if (e.quota != null) ...[const SizedBox(height: 16), EventQuotaNote(quota: e.quota!)],
                  if (e.program.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Semantics(header: true, child: Text(l.eventProgramTitle, style: AppTypography.display(20, color: p.ink))),
                    const SizedBox(height: 6),
                    Text(e.program, style: AppTypography.body(14, weight: FontWeight.w600, height: 1.55, color: p.mut)),
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

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => const Shimmer(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 270, radius: 0),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 180, height: 28, radius: 14),
                    SizedBox(height: 16),
                    SkeletonBox(width: 260, height: 30),
                    SizedBox(height: 20),
                    SkeletonBox(height: 44, radius: 14),
                    SizedBox(height: 12),
                    SkeletonBox(height: 44, radius: 14),
                    SizedBox(height: 12),
                    SkeletonBox(height: 44, radius: 14),
                    SizedBox(height: 16),
                    SkeletonBox(height: 110, radius: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

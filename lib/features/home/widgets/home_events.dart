import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_items.dart';
import '../../../l10n/l10n.dart';
import '../home_links.dart';

/// "Bu Hafta Etkinlikler": tarih karosu + başlık + yer · saat + kontenjan çubuğu.
class HomeEvents extends StatelessWidget {
  const HomeEvents({super.key, required this.events});

  final List<HomeEvent> events;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.l10n.homeEventsTitle, onAction: () => context.push(Routes.events)),
        for (final e in events)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: _EventRow(event: e),
          ),
      ],
    ),
  );
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final HomeEvent event;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final pct = event.capacity <= 0 ? 0.0 : event.filled / event.capacity;
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(Routes.event(event.id)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 60,
            decoration: BoxDecoration(color: toneColor(p, event.tone), borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${event.startsAt.day}', style: AppTypography.display(22, color: p.onTile, height: 1)),
                Text(
                  Fmt.monthShort(event.startsAt, locale),
                  style: AppTypography.body(11, weight: FontWeight.w900, color: p.onTile),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  l.homeEventPlaceTime(event.place, Fmt.time(event.startsAt, locale)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(12, color: p.mut),
                ),
                if (event.capacity > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: AppProgressBar(
                            value: pct,
                            color: p.tealB,
                            semanticsValue: l.homeEventCapacitySemantics(event.filled, event.capacity),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ExcludeSemantics(
                        child: Text(
                          l.homeEventCapacity(event.filled, event.capacity),
                          style: AppTypography.number(12, weight: FontWeight.w800, color: p.mut),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppIcon(AppIcons.chevronRight, size: 20, color: p.mut, strokeWidth: 2.4),
        ],
      ),
    );
  }
}

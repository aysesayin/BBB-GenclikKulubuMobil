import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/events/event_item.dart';
import '../../../l10n/l10n.dart';
import 'discover_palette.dart';
import 'event_format.dart';
import 'events_icons.dart';

/// G1 etkinlik kartı: 110 px renkli üst bant + başlık, yer, kontenjan çubuğu + metin, etiketler.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap});

  final EventItem event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: AppRadii.card,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Banner(event: event),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTypography.body(16, weight: FontWeight.w900, height: 1.25, color: p.ink),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AppIcon(AppIcons.pinSimple, size: 14, color: p.mut, strokeWidth: 2.4),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.placeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(13, color: p.mut),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _Capacity(event: event),
                if (event.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final t in event.tags) _Tag(label: t)]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final wave =
        '<svg viewBox="0 0 353 110" preserveAspectRatio="none"><path d="M-20 110 C60 40 130 80 190 50 S300 20 380 60 L380 110 Z" '
        'fill="${p.paper.hex}" fill-opacity=".35"/></svg>';
    return SizedBox(
      height: 110,
      child: ColoredBox(
        color: paletteColor(p, event.tone),
        child: Stack(
          children: [
            Positioned.fill(child: SvgArt(wave, fit: BoxFit.fill)),
            Positioned(
              right: 22,
              top: 0,
              bottom: 0,
              child: Center(child: AppIcon(EventIcons.forKey(event.icon), size: 54, color: p.onTile, strokeWidth: 1.8)),
            ),
            Positioned(left: 14, top: 14, child: TagBadge(label: event.categoryLabel, fontSize: 12)),
            Positioned(
              left: 14,
              bottom: 14,
              child: TagBadge(
                label: EventFormat.cardWhen(context, event.startsAt, event.endsAt),
                fontSize: 12,
                background: p.paper.withValues(alpha: .9),
                foreground: p.onTile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Capacity extends StatelessWidget {
  const _Capacity({required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final full = event.isFull;
    final bar = full ? p.hotFill : (event.isLow ? p.cta : p.primary);
    final textColor = full || event.isLow ? p.pinkT : p.mut;
    final label = full ? l.eventCapacityFull : '${event.attendeeCount}/${event.capacity}';
    return Semantics(
      label: l.eventCapacitySemantics(event.attendeeCount, event.capacity),
      excludeSemantics: !full,
      child: Row(
        children: [
          Expanded(
            child: AppProgressBar(value: event.fillRatio, color: bar, height: 8, semanticsValue: label),
          ),
          const SizedBox(width: 10),
          Text(label, style: AppTypography.number(12, color: textColor)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: p.sf2, borderRadius: BorderRadius.circular(12)),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: AppTypography.body(11, weight: FontWeight.w900, color: p.ink),
        ),
      ),
    );
  }
}

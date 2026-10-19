import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/events/event_detail.dart';
import '../../../l10n/l10n.dart';
import 'discover_palette.dart';
import 'events_icons.dart';

/// Bilgi satırı: 44 px ikon karosu + kalın başlık + gri alt satır.
class EventInfoRow extends StatelessWidget {
  const EventInfoRow({super.key, required this.icon, required this.title, this.subtitle, this.onTap, this.semanticLabel});

  final String icon, title;
  final String? subtitle;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final row = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: AppIcon(icon, size: 22, color: p.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) Text(subtitle!, style: AppTypography.body(13, color: p.mut)),
            ],
          ),
        ),
        if (onTap != null) AppIcon(AppIcons.chevronRight, size: 18, color: p.mut, strokeWidth: 2.4),
      ],
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: row),
    );
  }
}

/// Kontenjan kutusu: sayı + 10 px çubuk + katılımcı avatarları.
class EventCapacityBox extends StatelessWidget {
  const EventCapacityBox({super.key, required this.event});

  final EventDetail event;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final avatars = event.attendees.take(5).toList();
    final others = (event.attendeeCount - avatars.length).clamp(0, 1 << 30);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: l.eventCapacitySemantics(event.attendeeCount, event.capacity),
            excludeSemantics: true,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.eventCapacityLabel,
                    style: AppTypography.body(14, weight: FontWeight.w900, color: p.ink),
                  ),
                ),
                Text('${event.attendeeCount} / ${event.capacity}', style: AppTypography.number(14, color: p.ink)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AppProgressBar(value: event.fillRatio, height: 10, color: event.isFull ? p.hotFill : p.primary),
          if (avatars.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: 30 + 22.0 * (avatars.length - 1),
                    height: 30,
                    child: Stack(
                      children: [
                        for (var i = 0; i < avatars.length; i++)
                          Positioned(
                            left: 22.0 * i,
                            child: _Avatar(attendee: avatars[i]),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.eventAttendeesOthers(others),
                    style: AppTypography.body(13, weight: FontWeight.w800, color: p.mut),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.attendee});

  final EventAttendee attendee;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: paletteColor(p, attendee.tone),
        shape: BoxShape.circle,
        border: Border.all(color: p.bg, width: 2),
      ),
      child: Text(
        attendee.initials,
        style: AppTypography.body(11, weight: FontWeight.w900, color: p.onTile),
      ),
    );
  }
}

/// Kota uyarısı ("6 ayda 1 katılım.") — metin sunucudan.
class EventQuotaNote extends StatelessWidget {
  const EventQuotaNote({super.key, required this.quota});

  final EventQuota quota;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = AppTypography.body(13, height: 1.45, color: p.ink);
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: p.yelS, borderRadius: BorderRadius.circular(18)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: AppIcon(EventIcons.alert, size: 20, color: p.warningText, strokeWidth: 2.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: quota.title,
                      style: base.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (quota.message.isNotEmpty) TextSpan(text: ' ${quota.message}'),
                  ],
                ),
                style: base,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kategori + check-in BUAN çipleri.
class EventChips extends StatelessWidget {
  const EventChips({super.key, required this.event});

  final EventDetail event;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final buan = event.checkInBuan;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: paletteColor(p, event.tone), borderRadius: BorderRadius.circular(14)),
          child: Center(
            widthFactor: 1,
            child: Text(event.categoryLabel, style: AppTypography.body(12, weight: FontWeight.w900, color: p.onTile)),
          ),
        ),
        if (buan != null && buan > 0)
          Container(
            height: 28,
            padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
            decoration: BoxDecoration(color: p.purS, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BuanCoin(size: 20),
                const SizedBox(width: 6),
                Text(
                  context.l10n.eventCheckInBadge(Fmt.number(buan)),
                  maxLines: 1,
                  style: AppTypography.body(12, weight: FontWeight.w900, color: p.purT),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

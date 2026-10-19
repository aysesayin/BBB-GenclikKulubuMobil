import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../view_model/event_detail_view_model.dart';
import 'events_icons.dart';

/// G2 yapışkan alt çubuk: 56 px "Takvime ekle" + duruma göre başvuru CTA'sı.
class EventApplyBar extends StatelessWidget {
  const EventApplyBar({super.key, required this.cta, required this.busy, required this.onApply, required this.onCalendar});

  final EventCta cta;
  final bool busy;
  final VoidCallback onApply;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return StickyBottomBar(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: l.eventAddToCalendar,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onCalendar,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.line, width: 2)),
                  alignment: Alignment.center,
                  child: AppIcon(EventIcons.calendarPlus, size: 22, color: p.ink),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _cta(context)),
        ],
      ),
    );
  }

  Widget _cta(BuildContext context) {
    final l = context.l10n;
    return switch (cta) {
      EventCta.apply => AppButton(label: l.eventApply, busy: busy, onPressed: onApply),
      EventCta.waitlist => AppButton(label: l.eventJoinWaitlist, busy: busy, onPressed: onApply, variant: AppButtonVariant.outlineInk),
      EventCta.applied => _DoneButton(label: l.eventApplied),
      EventCta.waitlisted => _DoneButton(label: l.eventWaitlisted),
      EventCta.full => AppButton(label: l.eventFullCta, onPressed: null),
      EventCta.closed => AppButton(label: l.eventClosedCta, onPressed: null),
      EventCta.quotaBlocked => AppButton(label: l.eventQuotaBlockedCta, onPressed: null),
    };
  }
}

/// "Başvurun alındı" — yeşil yumuşak dolgu, onay işareti, gölgesiz (pasif).
class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 56,
        decoration: BoxDecoration(color: p.grnS, borderRadius: BorderRadius.circular(28)),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.check, size: 20, color: p.grnT, strokeWidth: 3),
            const SizedBox(width: 8),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.buttonL.copyWith(color: p.grnT))),
          ],
        ),
      ),
    );
  }
}

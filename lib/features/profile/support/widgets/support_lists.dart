import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/profile/support.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/profile_icons.dart';
import '../../widgets/profile_ui.dart';
import 'support_form.dart';

/// "Taleplerim" satırı: "#24817 · Konu", "Şikâyet · 12 Eki", durum hapı.
class TicketTile extends StatelessWidget {
  const TicketTile({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final (label, icon, bg, fg) = switch (ticket.status) {
      TicketStatus.answered => (l.profileTicketAnswered, AppIcons.check, p.grnS, p.grnT),
      TicketStatus.inReview => (l.profileTicketInReview, AppIcons.clock, p.yelS, p.warningText),
      TicketStatus.received => (l.profileTicketReceived, ProfileIcons.chat, p.tealS, p.teal),
      TicketStatus.closed => (l.profileTicketClosed, AppIcons.lock, p.sf2, p.mut),
    };
    final date = ProfileFmt.dayMonth(ticket.createdAt, Localizations.localeOf(context).languageCode);
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(
              child: TitleSubtitle(
                title: l.profileTicketTitle(ticket.number, ticket.subject),
                subtitle: l.profileTicketMeta(supportTypeLabel(l, ticket.type), date),
                titleSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            StatusPill(label: label, icon: icon, background: bg, foreground: fg, fontSize: 11),
          ],
        ),
      ),
    );
  }
}

/// SSS akordeonu: tek satır açık; chevron 180° döner ("hareketi azalt"ta anında).
class FaqList extends StatelessWidget {
  const FaqList({super.key, required this.items, required this.openIndex, required this.onToggle});

  final List<FaqItem> items;
  final int openIndex;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = context.reduceMotion;
    return DividedCard(
      radius: AppRadii.tile,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      lineColor: p.sf2,
      children: [
        for (var i = 0; i < items.length; i++)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                expanded: i == openIndex,
                child: InkWell(
                  onTap: () {
                    Haptics.selection();
                    onToggle(i);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 54),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              items[i].question,
                              style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedRotation(
                          turns: i == openIndex ? .5 : 0,
                          duration: reduce ? Duration.zero : AppDurations.fast,
                          child: AppIcon(AppIcons.chevronDown, size: 18, color: p.ink, strokeWidth: 2.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: reduce ? Duration.zero : AppDurations.fast,
                alignment: Alignment.topCenter,
                child: i == openIndex
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          items[i].answer,
                          style: AppTypography.body(14, weight: FontWeight.w600, color: p.mut, height: 1.5),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
      ],
    );
  }
}

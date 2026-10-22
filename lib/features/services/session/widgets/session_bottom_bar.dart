import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/session.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../view_model/session_view_model.dart';
import 'session_cell_sheet.dart';

/// Alt şerit: kural uyarıları, yüzme bilme onayı, seçim özeti ve "Sepete ekle".
class SessionBottomBar extends StatelessWidget {
  const SessionBottomBar({super.key, required this.vm, required this.onAdd});

  final SessionViewModel vm;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final slot = vm.selectedSlot;
    final week = vm.state.dataOrNull;
    return StickyBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final issue in vm.issues) ...[_IssueRow(issue: issue), const SizedBox(height: 8)],
          if (slot != null && vm.requiresSwim) ...[_SwimConfirm(vm: vm), const SizedBox(height: 4)],
          Semantics(
            liveRegion: true,
            child: Text(
              slot == null ? l.svcSelectPrompt : _summary(context, slot),
              style: AppTypography.body(13, weight: FontWeight.w800, color: p.mut),
            ),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: l.svcAddToCart('${week?.holdMinutes ?? 5}'),
            busy: vm.adding,
            onPressed: vm.canAdd ? onAdd : null,
          ),
        ],
      ),
    );
  }

  String _summary(BuildContext context, SessionSlot s) {
    final l = context.l10n;
    final base = l.svcSelected(SvcFmt.dayMonth(context, s.start), SvcFmt.time(context, s.start), s.label, SvcFmt.price(context, s.price));
    final late = s.lateJoinRate;
    return late == null || late <= 0 ? base : '$base · ${l.svcLateJoin('$late')}';
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});

  final RuleIssue issue;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = ruleIssueText(context, issue);
    final (bg, fg) = issue.blocking ? (p.pinkS, p.pinkT) : (p.yelS, p.warningText);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(issue.blocking ? SvcIcons.alert : AppIcons.info, size: 16, color: fg, strokeWidth: 2.6),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTypography.body(12, weight: FontWeight.w800, color: fg, height: 1.35))),
        ],
      ),
    );
  }
}

class _SwimConfirm extends StatelessWidget {
  const _SwimConfirm({required this.vm});

  final SessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      checked: vm.swimConfirmed,
      excludeSemantics: true,
      label: context.l10n.svcSwimConfirm,
      child: InkWell(
        onTap: () => vm.setSwimConfirmed(value: !vm.swimConfirmed),
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Checkbox(value: vm.swimConfirmed, onChanged: (v) => vm.setSwimConfirmed(value: v ?? false)),
              Expanded(child: Text(context.l10n.svcSwimConfirm, style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink))),
            ],
          ),
        ),
      ),
    );
  }
}

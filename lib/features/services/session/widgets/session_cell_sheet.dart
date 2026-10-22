import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/session.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../view_model/session_view_model.dart';

/// Kural uyarısının kullanıcı metni (alt şerit, hücre tooltip'i ve neden sayfası ortak).
String ruleIssueText(BuildContext context, RuleIssue issue) {
  final l = context.l10n;
  return switch (issue.kind) {
    RuleIssueKind.gender => l.svcRuleGender(issue.gender == Gender.male ? l.svcGenderMale : l.svcGenderFemale),
    RuleIssueKind.minAge => l.svcRuleMinAge('${issue.min}'),
    RuleIssueKind.maxAge => l.svcRuleMaxAge('${issue.max}'),
    RuleIssueKind.guardian => l.svcRuleGuardian('${issue.min}', '${issue.max}'),
    RuleIssueKind.permission => l.svcRulePermission('${issue.min}', '${issue.max}'),
  };
}

/// Hücreye dokunma: açık/seçili → seç; DOLU → bekleme listesi sayfası; uygun değil → neden sayfası.
void handleCellTap(BuildContext context, SessionViewModel vm, {required SessionSlot? slot, required SessionDay day, required CellKind kind}) {
  if (slot == null) return;
  switch (kind) {
    case CellKind.open || CellKind.selected:
      vm.select(slot, day);
    case CellKind.full:
      _showWaitlistSheet(context, vm, slot);
    case CellKind.ineligible:
      final issue = vm.ineligibilityOf(slot);
      if (issue != null) _showIneligibleSheet(context, slot, issue);
    default:
      break;
  }
}

Future<void> _showWaitlistSheet(BuildContext context, SessionViewModel vm, SessionSlot slot) => AppSheet.show<void>(
      context,
      builder: (_) => ChangeNotifierProvider.value(value: vm, child: _WaitlistSheet(slot: slot)),
    );

Future<void> _showIneligibleSheet(BuildContext context, SessionSlot slot, RuleIssue issue) => AppSheet.show<void>(
      context,
      builder: (ctx) => _ReasonSheet(
        title: ctx.l10n.svcIneligibleSheetTitle,
        subtitle: ctx.l10n.svcIneligibleSheetBody(SvcFmt.dayMonth(ctx, slot.start), SvcFmt.time(ctx, slot.start), slot.label),
        body: ruleIssueText(ctx, issue),
        hint: ctx.l10n.svcIneligibleHint,
      ),
    );

class _WaitlistSheet extends StatelessWidget {
  const _WaitlistSheet({required this.slot});

  final SessionSlot slot;

  Future<void> _join(BuildContext context, SessionViewModel vm) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final pos = await vm.joinWaitlist(slot);
    if (!context.mounted) return;
    if (pos != null) {
      Haptics.medium();
      Navigator.of(context).pop();
      messenger?.showSnackBar(SnackBar(content: Text(l.svcWaitlistPosition('$pos'))));
    } else if (vm.takeError() case final e?) {
      messenger?.showSnackBar(SnackBar(content: Text(errorMessageOf(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<SessionViewModel>();
    final pos = vm.waitlistPositionOf(slot.id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l.svcWaitlistSheetTitle, style: AppTypography.display(24, color: p.ink))),
        const SizedBox(height: 6),
        Text(
          l.svcWaitlistSheetBody(SvcFmt.dayMonth(context, slot.start), SvcFmt.time(context, slot.start), slot.label),
          style: AppTypography.body(14, color: p.mut, height: 1.4),
        ),
        const SizedBox(height: 18),
        if (pos != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: p.tealS, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                AppIcon(AppIcons.check, size: 18, color: p.teal, strokeWidth: 2.8),
                const SizedBox(width: 10),
                Expanded(child: Text(l.svcWaitlistPosition('$pos'), style: AppTypography.body(14, weight: FontWeight.w900, color: p.ink))),
              ],
            ),
          )
        else
          AppButton(label: l.svcWaitlistJoin, busy: vm.joiningWaitlist, onPressed: () => _join(context, vm)),
      ],
    );
  }
}

class _ReasonSheet extends StatelessWidget {
  const _ReasonSheet({required this.title, required this.subtitle, required this.body, required this.hint});

  final String title, subtitle, body, hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: AppTypography.display(24, color: p.ink))),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTypography.body(13, weight: FontWeight.w800, color: p.mut)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: p.pinkS, borderRadius: BorderRadius.circular(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(SvcIcons.alert, size: 16, color: p.pinkT, strokeWidth: 2.6),
              const SizedBox(width: 8),
              Expanded(child: Text(body, style: AppTypography.body(13, weight: FontWeight.w800, color: p.pinkT, height: 1.35))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(hint, style: AppTypography.body(13, color: p.mut, height: 1.4)),
        const SizedBox(height: 8),
        AppButton.outline(label: context.l10n.commonClose, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

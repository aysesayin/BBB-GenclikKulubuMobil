import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/profile/support.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/dashed_drop_zone.dart';
import '../../widgets/document_picker.dart';
import '../../widgets/profile_icons.dart';
import '../../widgets/profile_ui.dart';
import '../view_model/support_view_model.dart';

String supportTypeLabel(AppLocalizations l, SupportType t) => switch (t) {
  SupportType.oneri => l.profileSupportTypeOneri,
  SupportType.sikayet => l.profileSupportTypeSikayet,
  SupportType.talep => l.profileSupportTypeTalep,
};

/// Öneri / Şikâyet / Talep formu.
class SupportForm extends StatefulWidget {
  const SupportForm({super.key});

  @override
  State<SupportForm> createState() => _SupportFormState();
}

class _SupportFormState extends State<SupportForm> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  String _topicLabel(AppLocalizations l, SupportTopic t) => switch (t) {
    SupportTopic.facilities => l.profileTopicFacilities,
    SupportTopic.opportunities => l.profileTopicOpportunities,
    SupportTopic.buan => l.profileTopicBuan,
    SupportTopic.appBug => l.profileTopicAppBug,
  };

  String _hint(AppLocalizations l, SupportType t) => switch (t) {
    SupportType.oneri => l.profileSupportHintOneri,
    SupportType.sikayet => l.profileSupportHintSikayet,
    SupportType.talep => l.profileSupportHintTalep,
  };

  Future<void> _attach() async {
    final vm = context.read<SupportViewModel>();
    final doc = await pickDocument(context);
    if (doc != null) vm.setAttachment(doc);
  }

  Future<void> _send() async {
    final vm = context.read<SupportViewModel>();
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    final ticket = await vm.submit(_message.text);
    if (ticket == null || !mounted) return;
    _message.clear();
    Haptics.medium();
    showProfileSnack(context, l.profileSupportSent(ticket.number));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SupportViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final labelStyle = AppTypography.body(14, weight: FontWeight.w800, color: p.ink);
    final att = vm.attachment;
    final issue = switch (vm.issue) {
      SupportFormIssue.messageShort => l.profileSupportMessageShort,
      SupportFormIssue.tooLarge => l.profileDiscountTooLarge,
      null => vm.error == null ? null : errorMessageOf(context, vm.error!),
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            labels: [for (final t in SupportType.values) supportTypeLabel(l, t)],
            index: vm.type.index,
            onChanged: (i) => vm.setType(SupportType.values[i]),
          ),
          const SizedBox(height: 12),
          Text(l.profileSupportTopic, style: labelStyle),
          const SizedBox(height: 6),
          DropdownButtonFormField<SupportTopic>(
            initialValue: vm.topic,
            isExpanded: true,
            borderRadius: BorderRadius.circular(AppRadii.md),
            dropdownColor: p.sf,
            icon: AppIcon(AppIcons.chevronDown, size: 18, color: p.mut, strokeWidth: 2.6),
            style: AppTypography.body(15, color: p.ink),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
            items: [for (final t in SupportTopic.values) DropdownMenuItem(value: t, child: Text(_topicLabel(l, t)))],
            onChanged: (t) {
              if (t != null) vm.setTopic(t);
            },
          ),
          const SizedBox(height: 12),
          Text(l.profileSupportMessage, style: labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _message,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => vm.clearIssue(),
            style: AppTypography.body(15, weight: FontWeight.w600, color: p.ink),
            decoration: InputDecoration(
              hintText: _hint(l, vm.type),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          if (att != null) ...[
            const SizedBox(height: 12),
            PickedFileRow(name: att.name, removeLabel: l.profileSupportRemoveAttachment, onRemove: () => vm.setAttachment(null)),
          ],
          if (issue != null) ...[const SizedBox(height: 12), InlineAlert(issue)],
          const SizedBox(height: 12),
          Row(
            children: [
              _AttachButton(label: l.profileSupportAttach, onTap: vm.sending ? null : _attach),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(label: l.profileSupportSend, size: AppButtonSize.medium, busy: vm.sending, onPressed: _send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: p.line, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(ProfileIcons.paperclip, size: 18, color: p.ink, strokeWidth: 2.4),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.body(14, weight: FontWeight.w900, color: p.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

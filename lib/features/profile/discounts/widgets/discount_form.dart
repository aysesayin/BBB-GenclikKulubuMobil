import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/dashed_drop_zone.dart';
import '../../widgets/document_picker.dart';
import '../../widgets/profile_ui.dart';
import '../view_model/discounts_view_model.dart';

/// "Yeni indirim ekle" kartı: tür çipleri, gerekli belge, yükleme alanı, seçili dosya.
class DiscountForm extends StatelessWidget {
  const DiscountForm({super.key, required this.data});

  final DiscountsData data;

  Future<void> _pick(BuildContext context) async {
    final vm = context.read<DiscountsViewModel>();
    final doc = await pickDocument(context);
    if (doc != null) vm.setDocument(doc);
  }

  String? _issueText(AppLocalizations l, DiscountFormIssue? issue) => switch (issue) {
    DiscountFormIssue.noType => l.profileDiscountSelectType,
    DiscountFormIssue.noDocument => l.profileDiscountNeedDoc,
    DiscountFormIssue.tooLarge => l.profileDiscountTooLarge,
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscountsViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final selected = vm.selectedType;
    final doc = vm.document;
    final issue = _issueText(l, vm.issue);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l.profileDiscountNew, style: AppTypography.display(20, color: p.ink)),
          ),
          const SizedBox(height: 14),
          Semantics(
            label: l.profileDiscountTypeLabel,
            container: true,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in data.types)
                  FilterPill(label: t.name, selected: t.id == vm.selectedTypeId, onTap: () => vm.selectType(t.id)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            selected == null ? l.profileDiscountSelectType : l.profileDiscountRequiredDoc(selected.requiredDocument),
            style: AppTypography.body(13, color: p.mut),
          ),
          const SizedBox(height: 14),
          DashedDropZone(title: l.profileDiscountUpload, hint: l.profileDiscountUploadHint, onTap: () => _pick(context)),
          if (doc != null) ...[
            const SizedBox(height: 14),
            PickedFileRow(name: doc.name, removeLabel: l.profileDiscountRemoveFile, onRemove: () => vm.setDocument(null)),
          ],
          if (issue != null) ...[const SizedBox(height: 14), InlineAlert(issue)],
          if (vm.error != null) ...[const SizedBox(height: 14), InlineAlert(errorMessageOf(context, vm.error!))],
          const SizedBox(height: 14),
          Text(l.profileDiscountNote, style: AppTypography.body(12, color: p.mut)),
        ],
      ),
    );
  }
}

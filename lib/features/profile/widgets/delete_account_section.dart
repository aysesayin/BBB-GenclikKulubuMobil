import 'package:flutter/material.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'confirm_sheet.dart';
import 'profile_ui.dart';

/// KVKK hesap silme talebi: pembe çerçeveli buton + açıklama. Onay sheet'i sonrası [onRequest]
/// çağrılır (null → başarı).
class DeleteAccountSection extends StatefulWidget {
  const DeleteAccountSection({super.key, required this.onRequest});

  final Future<AppException?> Function() onRequest;

  @override
  State<DeleteAccountSection> createState() => _DeleteAccountSectionState();
}

class _DeleteAccountSectionState extends State<DeleteAccountSection> {
  bool _busy = false;

  Future<void> _start() async {
    final l = context.l10n;
    final ok = await showConfirmSheet(
      context,
      title: l.profileDeleteConfirmTitle,
      message: l.profileDeleteConfirmMessage,
      confirmLabel: l.profileDeleteConfirmCta,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final error = await widget.onRequest();
    if (!mounted) return;
    setState(() => _busy = false);
    showProfileSnack(context, error == null ? l.profileDeleteDone : errorMessageOf(context, error));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          enabled: !_busy,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _busy ? null : _start,
              borderRadius: BorderRadius.circular(26),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: p.pinkT, width: 2),
                ),
                child: _busy
                    ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 3, color: p.pinkT))
                    : Text(
                        l.profileDeleteCta,
                        style: AppTypography.body(15, weight: FontWeight.w900, color: p.pinkT),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.profileDeleteNote,
          textAlign: TextAlign.center,
          style: AppTypography.body(12, color: p.mut),
        ),
      ],
    );
  }
}

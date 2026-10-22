import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_result.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/profile/delete_request.dart';
import '../../../l10n/l10n.dart';
import 'confirm_sheet.dart';
import 'profile_ui.dart';

/// KVKK hesap silme talebi: pembe çerçeveli buton + açıklama. Onay sheet'i sonrası [onRequest]
/// çağrılır; başarıda makbuzla [Routes.deleteRequested] ekranına geçilir, hatada snackbar.
class DeleteAccountSection extends StatefulWidget {
  const DeleteAccountSection({super.key, required this.onRequest});

  final Future<ApiResult<DeleteRequestReceipt>> Function() onRequest;

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
    final result = await widget.onRequest();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(:final data):
        context.go(Routes.deleteRequested, extra: data);
      case Failure(:final error):
        showProfileSnack(context, errorMessageOf(context, error));
    }
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

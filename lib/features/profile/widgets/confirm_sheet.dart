import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';

/// Onay alt sayfası (çıkış, hesap silme). true → onaylandı.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await AppSheet.show<bool>(
    context,
    builder: (ctx) {
      final p = ctx.palette;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: AppTypography.display(24, height: 1.1, color: p.ink)),
          ),
          const SizedBox(height: 10),
          Text(message, style: AppTypography.body(15, color: p.mut, height: 1.4)),
          const SizedBox(height: 20),
          if (destructive)
            _DestructiveButton(label: confirmLabel, onTap: () => Navigator.of(ctx).pop(true))
          else
            AppButton(label: confirmLabel, onPressed: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: 8),
          AppButton(
            label: ctx.l10n.commonCancel,
            variant: AppButtonVariant.outlineInk,
            size: AppButtonSize.medium,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      child: Material(
        color: p.pinkT,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(label, style: AppTypography.buttonL.copyWith(color: p.isDark ? p.bg : p.paper)),
            ),
          ),
        ),
      ),
    );
  }
}

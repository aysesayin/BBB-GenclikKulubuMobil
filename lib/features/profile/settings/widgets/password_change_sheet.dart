import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/profile_icons.dart';
import '../../widgets/profile_ui.dart';
import '../view_model/password_change_view_model.dart';

/// Şifre güncelleme sheet'i. true → güncellendi.
Future<bool> showPasswordChangeSheet(BuildContext context) async {
  final result = await AppSheet.show<bool>(
    context,
    builder: (_) => ChangeNotifierProvider(create: (_) => PasswordChangeViewModel(sl<ProfileRepository>()), child: const _PasswordBody()),
  );
  return result ?? false;
}

class _PasswordBody extends StatefulWidget {
  const _PasswordBody();

  @override
  State<_PasswordBody> createState() => _PasswordBodyState();
}

class _PasswordBodyState extends State<_PasswordBody> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit(PasswordChangeViewModel vm) async {
    final ok = await vm.submit(current: _current.text, next: _next.text, repeat: _repeat.text);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PasswordChangeViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final toggle = AppIconButton(
      icon: _obscure ? ProfileIcons.eye : ProfileIcons.eyeOff,
      semanticLabel: _obscure ? l.profileShowPassword : l.profileHidePassword,
      color: p.mut,
      iconSize: 20,
      onPressed: () => setState(() => _obscure = !_obscure),
    );
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l.profilePasswordTitle, style: AppTypography.display(24, color: p.ink)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: l.profilePasswordCurrent,
            controller: _current,
            obscure: _obscure,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.next,
            errorText: vm.currentIssue == null ? null : validationText(l, vm.currentIssue!),
            suffix: toggle,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: l.profilePasswordNew,
            controller: _next,
            obscure: _obscure,
            hint: l.profilePasswordRule,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            errorText: vm.nextIssue == null ? null : validationText(l, vm.nextIssue!),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: l.profilePasswordRepeat,
            controller: _repeat,
            obscure: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            errorText: vm.mismatch ? l.profileErrPasswordMismatch : null,
            onSubmitted: (_) => _submit(vm),
          ),
          if (vm.error != null) ...[const SizedBox(height: 12), InlineAlert(errorMessageOf(context, vm.error!))],
          const SizedBox(height: 18),
          AppButton(label: l.profileUpdate, busy: vm.busy, onPressed: () => _submit(vm)),
        ],
      ),
    );
  }
}

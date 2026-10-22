import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/auth/auth_requests.dart';
import '../../../l10n/l10n.dart';
import '../../onboarding/widgets/motion.dart';
import '../../onboarding/widgets/onb_icons.dart';
import '../view_model/login_view_model.dart';
import 'floating_field.dart';

/// A6 · Alt form sayfası: yöntem sekmeleri, kimlik + şifre, Face ID, kayıt bağlantısı.
class LoginForm extends StatelessWidget {
  const LoginForm({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<LoginViewModel>();
    final (idLabel, keyboard, hints, formatters) = switch (vm.method) {
      LoginMethod.tckn => (l.authTcknLabel, TextInputType.number, [AutofillHints.username], [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]),
      LoginMethod.phone => (l.authPhoneLabel, TextInputType.phone, [AutofillHints.telephoneNumber], [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]),
      LoginMethod.email => (l.authEmailLabel, TextInputType.emailAddress, [AutofillHints.email], <TextInputFormatter>[]),
    };
    final pwError = vm.error == LoginError.wrongPassword || vm.error == LoginError.passwordRequired || vm.error == LoginError.locked;
    final touch = context.touchTarget;

    Future<void> submit() async {
      FocusScope.of(context).unfocus();
      final ok = await vm.submit();
      if (ok) {
        TextInput.finishAutofillContext();
        Haptics.medium();
        onSuccess();
      } else if (pwErrorOf(vm.error)) {
        Haptics.error();
      }
    }

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          SegmentedTabs(
            labels: [l.authTabTckn, l.authTabPhone, l.authTabEmail],
            index: vm.method.index,
            onChanged: (i) => vm.setMethod(LoginMethod.values[i]),
          ),
          const SizedBox(height: 14),
          FloatingField(
            key: ValueKey(vm.method),
            label: idLabel,
            keyboardType: keyboard,
            inputFormatters: formatters,
            autofillHints: hints,
            error: vm.error == LoginError.identifier,
            textInputAction: TextInputAction.next,
            onChanged: vm.setIdentifier,
          ),
          if (vm.identifierIssue != null) _ErrorLine(text: issueText(context, vm.identifierIssue!, vm.method)),
          const SizedBox(height: 14),
          ShakeX(
            trigger: vm.shakeTick,
            child: FloatingField(
              label: l.authPassword,
              obscure: vm.obscure,
              error: pwError,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onChanged: vm.setPassword,
              onSubmitted: (_) => submit(),
              suffix: AppIconButton(
                icon: vm.obscure ? OnbIcons.eye : OnbIcons.eyeOff,
                semanticLabel: vm.obscure ? l.authShowPassword : l.authHidePassword,
                color: p.mut,
                size: touch,
                onPressed: vm.toggleObscure,
              ),
            ),
          ),
          _ErrorLine(text: _errorText(context, vm)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _forgot(context, vm),
              style: TextButton.styleFrom(minimumSize: Size(touch, touch - 4), foregroundColor: p.teal),
              child: Text(l.authForgot, style: AppTypography.body(14, weight: FontWeight.w900, color: p.teal)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: vm.busy ? l.authLoggingIn : l.authLogin,
                  busy: vm.busy,
                  onPressed: vm.error == LoginError.locked ? null : submit,
                ),
              ),
              const SizedBox(width: 12),
              _FaceIdButton(
                onTap: () async {
                  if (await vm.biometricLogin(l.authBiometricReason)) onSuccess();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.authNoAccount, style: AppTypography.body(14, color: p.mut)),
              TextButton(
                onPressed: () => context.push(Routes.interests),
                style: TextButton.styleFrom(minimumSize: Size(touch, touch), padding: const EdgeInsets.symmetric(horizontal: 6)),
                child: Text(l.authRegisterLink, style: AppTypography.body(14, weight: FontWeight.w900, color: p.teal)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool pwErrorOf(LoginError e) => e == LoginError.wrongPassword || e == LoginError.passwordRequired || e == LoginError.locked;

  String? _errorText(BuildContext context, LoginViewModel vm) {
    final l = context.l10n;
    return switch (vm.error) {
      LoginError.passwordRequired => l.authPasswordRequired,
      LoginError.wrongPassword => l.authWrongPassword(vm.remainingAttempts),
      LoginError.locked => l.authLocked,
      LoginError.biometricUnavailable => l.authBiometricUnavailable,
      LoginError.other when vm.failure != null => errorMessageOf(context, vm.failure!),
      _ => null,
    };
  }

  Future<void> _forgot(BuildContext context, LoginViewModel vm) async {
    final l = context.l10n;
    final p = context.palette;
    await AppSheet.show<void>(
      context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: vm,
        child: Consumer<LoginViewModel>(
          builder: (ctx, vm, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(l.authForgotTitle, style: AppTypography.display(24, color: p.ink))),
              const SizedBox(height: 8),
              Text(vm.forgotSent ? l.authForgotSent : l.authForgotBody, style: AppTypography.body(15, color: p.mut, height: 1.4)),
              const SizedBox(height: 20),
              AppButton(
                label: vm.forgotSent ? l.commonDone : l.authForgotSend,
                onPressed: () async {
                  if (vm.forgotSent) {
                    Navigator.of(ctx).pop();
                  } else if (!await vm.forgotPassword() && ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Validators sonucunu yerelleştirilmiş kısa mesaja çevirir.
String issueText(BuildContext context, ValidationIssue issue, [LoginMethod? method]) {
  final l = context.l10n;
  return switch (issue) {
    ValidationIssue.required => l.authFieldRequired,
    ValidationIssue.tcknLength => l.authTcknIncomplete,
    ValidationIssue.tcknInvalid => l.authTcknInvalid,
    ValidationIssue.phoneInvalid => l.authPhoneInvalid,
    ValidationIssue.emailInvalid => l.authEmailInvalid,
    _ => l.authFieldRequired,
  };
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 18),
            child: Text(text ?? '', style: AppTypography.body(13, weight: FontWeight.w900, color: context.palette.errorText)),
          ),
        ),
      );
}

class _FaceIdButton extends StatelessWidget {
  const _FaceIdButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: context.l10n.authBiometric,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.buanFill,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: p.buanShadow.withValues(alpha: .47), blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: AppIcon(OnbIcons.faceId, size: 36, color: p.onBuan, strokeWidth: 2),
        ),
      ),
    );
  }
}

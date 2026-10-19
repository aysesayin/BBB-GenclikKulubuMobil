import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/profile/account_settings.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/profile_ui.dart';
import '../view_model/contact_change_view_model.dart';

/// Telefon / e-posta değiştirme sheet'i (OTP adımlı). true → güncellendi.
Future<bool> showContactChangeSheet(BuildContext context, ContactKind kind) async {
  final result = await AppSheet.show<bool>(
    context,
    builder: (_) =>
        ChangeNotifierProvider(create: (_) => ContactChangeViewModel(sl<ProfileRepository>(), kind), child: const _ContactChangeBody()),
  );
  return result ?? false;
}

class _ContactChangeBody extends StatefulWidget {
  const _ContactChangeBody();

  @override
  State<_ContactChangeBody> createState() => _ContactChangeBodyState();
}

class _ContactChangeBodyState extends State<_ContactChangeBody> {
  final _value = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify(ContactChangeViewModel vm) async {
    final ok = await vm.verify(_code.text);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _resend(ContactChangeViewModel vm) async {
    final l = context.l10n;
    final ok = await vm.resend();
    if (ok && mounted) showProfileSnack(context, l.profileOtpResent);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ContactChangeViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final phone = vm.kind == ContactKind.phone;
    final verifying = vm.step == ContactStep.verify;
    final issue = vm.issue;
    final title = verifying ? l.profileOtpTitle : (phone ? l.profileContactPhoneTitle : l.profileContactEmailTitle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTypography.display(24, color: p.ink)),
        ),
        const SizedBox(height: 14),
        if (!verifying)
          AppTextField(
            label: phone ? l.profileContactNewPhone : l.profileContactNewEmail,
            controller: _value,
            hint: phone ? l.profilePhoneHint : null,
            keyboardType: phone ? TextInputType.phone : TextInputType.emailAddress,
            autofillHints: [if (phone) AutofillHints.telephoneNumber else AutofillHints.email],
            inputFormatters: phone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)] : null,
            textInputAction: TextInputAction.done,
            errorText: issue == null ? null : validationText(l, issue),
            onSubmitted: (_) => vm.sendCode(_value.text),
          )
        else ...[
          Text(
            l.profileOtpSentTo(phone ? Fmt.groupPhone(vm.target) : vm.target, vm.codeLength),
            style: AppTypography.body(15, color: p.mut, height: 1.4),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: l.profileOtpLabel,
            controller: _code,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(vm.codeLength)],
            letterSpacing: 6,
            errorText: issue == null ? null : validationText(l, issue, otpLength: vm.codeLength),
            onSubmitted: (_) => _verify(vm),
          ),
        ],
        if (vm.error != null) ...[const SizedBox(height: 12), InlineAlert(errorMessageOf(context, vm.error!))],
        const SizedBox(height: 18),
        AppButton(
          label: verifying ? l.profileOtpVerify : l.profileContactSendCode,
          busy: vm.busy,
          onPressed: () => verifying ? _verify(vm) : vm.sendCode(_value.text),
        ),
        if (verifying) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: AppButton.text(label: l.profileOtpResend, onPressed: vm.busy ? null : () => _resend(vm)),
              ),
              Expanded(
                child: AppButton.text(label: l.profileOtpEditTarget, onPressed: vm.busy ? null : vm.editTarget),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

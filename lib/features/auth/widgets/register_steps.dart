import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/services/auth_service.dart';
import '../../../l10n/l10n.dart';
import '../../onboarding/widgets/motion.dart';
import '../../onboarding/widgets/onb_icons.dart';
import '../view_model/register_view_model.dart';
import 'big_field.dart';
import 'birth_wheel.dart';
import 'digit_boxes.dart';
import 'login_form.dart' show issueText;

/// Adım başlığı: Baloo 40/800.
class StepTitle extends StatelessWidget {
  const StepTitle(this.text, {super.key, this.size = 40});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Text(text, style: AppTypography.display(size, height: size < 40 ? 1.02 : 1, color: context.palette.ink)));
}

class StepNote extends StatelessWidget {
  const StepNote(this.text, {super.key, this.size = 15});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(text, style: AppTypography.body(size, height: 1.45, color: context.palette.mut));
}

/// 1 · Tophane — T.C. Kimlik No (11 kutu, anında algoritma kontrolü) + doğum tarihi.
class IdentityStep extends StatelessWidget {
  const IdentityStep({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<RegisterViewModel>();
    final status = vm.tcknStatus;
    final (String msg, Color color) = switch (status) {
      TcknStatus.valid => (l.authTcknValid, p.successText),
      TcknStatus.invalid => (l.authTcknInvalid, p.errorText),
      TcknStatus.incomplete => (vm.showIssues ? l.authTcknIncomplete : '', p.errorText),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepTitle(l.authRegIdentityTitle),
        const SizedBox(height: 18),
        _Label(l.authTcknLabel),
        ShakeX(
          trigger: vm.shakeTick,
          child: DigitBoxes(
            length: 11,
            value: vm.tckn,
            onChanged: vm.setTckn,
            semanticLabel: l.authTcknSemantics,
            state: switch (status) {
              TcknStatus.valid => DigitBoxesState.valid,
              TcknStatus.invalid => DigitBoxesState.invalid,
              TcknStatus.incomplete => vm.showIssues ? DigitBoxesState.invalid : DigitBoxesState.normal,
            },
          ),
        ),
        _Status(text: msg, color: color, ok: status == TcknStatus.valid),
        const SizedBox(height: 10),
        _Label(l.authBirthLabel),
        BirthWheel(value: vm.birthDate, firstYear: vm.firstYear, lastYear: vm.lastYear, onChanged: vm.setBirthDate),
      ],
    );
  }
}

/// 2 · Ulu Cami — cep telefonu (+90) ve e-posta.
class ContactStep extends StatelessWidget {
  const ContactStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<RegisterViewModel>();
    final show = vm.showIssues;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepTitle(l.authRegContactTitle),
          const SizedBox(height: 18),
          BigField(
            label: l.authPhoneLabel,
            prefix: l.authCountryCode,
            height: 68,
            radius: 20,
            fontSize: 28,
            weight: FontWeight.w800,
            letterSpacing: 1,
            initial: vm.phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: const [PhoneGroupFormatter()],
            textInputAction: TextInputAction.next,
            error: show && vm.phoneIssue != null ? issueText(context, vm.phoneIssue!) : null,
            onChanged: vm.setPhone,
          ),
          const SizedBox(height: 18),
          BigField(
            label: l.authEmailLabel,
            height: 64,
            radius: 20,
            initial: vm.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            error: show && vm.emailIssue != null ? issueText(context, vm.emailIssue!) : null,
            onChanged: vm.setEmail,
          ),
          const SizedBox(height: 18),
          StepNote(l.authContactHint, size: 13),
        ],
      ),
    );
  }
}

/// 2b · SMS kodu — 6 kutu, SMS autofill (one-time-code), yanlışta sallanma.
class OtpStep extends StatelessWidget {
  const OtpStep({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<RegisterViewModel>();
    final state = vm.otpState;
    final left = vm.resendLeft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepTitle(l.authRegOtpTitle),
        const SizedBox(height: 18),
        StepNote(l.authOtpSent(vm.maskedPhone)),
        const SizedBox(height: 18),
        ShakeX(
          trigger: vm.shakeTick,
          child: DigitBoxes(
            length: 6,
            value: vm.otp,
            onChanged: vm.setOtp,
            semanticLabel: l.authOtpSemantics,
            height: 68,
            radius: 18,
            border: 3,
            gap: 8,
            fontSize: 34,
            autofocus: true,
            validFill: true,
            // TODO(varsayım): Android'de SMS Retriever paketi yok; iOS one-time-code autofill çalışır.
            autofillHints: const [AutofillHints.oneTimeCode],
            state: switch (state) {
              OtpState.ok => DigitBoxesState.valid,
              OtpState.wrong => DigitBoxesState.invalid,
              _ => DigitBoxesState.normal,
            },
          ),
        ),
        _Status(
          text: switch (state) {
            OtpState.wrong => l.authOtpWrong,
            OtpState.ok => l.authOtpOk,
            _ => '',
          },
          color: state == OtpState.wrong ? p.errorText : p.successText,
        ),
        if (ApiConfig.useMock) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              onPressed: () => vm.setOtp(AuthDemo.otpCode),
              avatar: AppIcon(OnbIcons.sms, size: 18, color: p.ink, strokeWidth: 2.4),
              label: Text(l.authOtpAutofill(AuthDemo.otpCode), style: AppTypography.body(14, weight: FontWeight.w900, color: p.ink)),
              backgroundColor: p.sf2,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: left > 0 ? null : vm.resendOtp,
            style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 4)),
            child: Text(
              left > 0 ? l.authOtpResendIn('0:${left.toString().padLeft(2, '0')}') : l.authOtpResend,
              style: AppTypography.number(14, weight: FontWeight.w800, color: left > 0 ? p.mut : p.teal),
            ),
          ),
        ),
      ],
    );
  }
}

/// 3 · Kozahan — acil durum kişisi.
class EmergencyStep extends StatelessWidget {
  const EmergencyStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<RegisterViewModel>();
    final show = vm.showIssues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepTitle(l.authRegEmergencyTitle, size: 38),
        const SizedBox(height: 18),
        StepNote(l.authEmergencySub),
        const SizedBox(height: 18),
        BigField(
          label: l.authEmergencyName,
          initial: vm.emergencyName,
          capitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          error: show && vm.emergencyNameIssue != null ? issueText(context, vm.emergencyNameIssue!) : null,
          onChanged: vm.setEmergencyName,
        ),
        const SizedBox(height: 18),
        BigField(
          label: l.authEmergencyPhone,
          initial: vm.emergencyPhone,
          hint: l.authPhoneHint,
          keyboardType: TextInputType.phone,
          inputFormatters: const [PhoneGroupFormatter(leadingZero: true)],
          error: show && vm.emergencyPhoneIssue != null ? issueText(context, vm.emergencyPhoneIssue!) : null,
          onChanged: vm.setEmergencyPhone,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ExcludeSemantics(child: Text(text, style: AppTypography.body(14, weight: FontWeight.w900, color: context.palette.mut))),
      );
}

class _Status extends StatelessWidget {
  const _Status({required this.text, required this.color, this.ok = false});

  final String text;
  final Color color;
  final bool ok;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 30),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ok) ...[AppIcon(AppIcons.check, size: 18, color: color, strokeWidth: 3), const SizedBox(width: 6)],
                Expanded(child: Text(text, style: AppTypography.body(14, weight: FontWeight.w900, color: color))),
              ],
            ),
          ),
        ),
      );
}

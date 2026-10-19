import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/interests_repository.dart';
import '../../../l10n/l10n.dart';
import '../../onboarding/widgets/motion.dart';
import '../../onboarding/widgets/nav_x.dart';
import '../view_model/register_view_model.dart';
import '../widgets/register_final_steps.dart';
import '../widgets/register_route_bar.dart';
import '../widgets/register_steps.dart';
import '../widgets/verification_scene.dart';

/// A5 · Kayıt — "Uludağ'a tırmanış". `?ref=` davet kodu okunur.
class RegisterView extends StatelessWidget {
  const RegisterView({super.key, this.referralCode});

  final String? referralCode;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => RegisterViewModel(
          sl<AuthRepository>(),
          sl<InterestsRepository>(),
          sl<AppRepository>(),
          sl<SessionController>(),
          referralCode: (referralCode?.isEmpty ?? true) ? null : referralCode,
        ),
        child: const RegisterBody(),
      );
}

/// Testlerde sağlayıcıyla doğrudan sarılabilir.
class RegisterBody extends StatefulWidget {
  const RegisterBody({super.key});

  @override
  State<RegisterBody> createState() => _RegisterBodyState();
}

class _RegisterBodyState extends State<RegisterBody> {
  late final RegisterViewModel _vm = context.read<RegisterViewModel>();
  int _shake = 0;
  Object? _shownError;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_react);
  }

  /// Hatalı giriş → errorImpact; ağ/sunucu hatası → snackbar (doğrulama sahnesi kendi gösterir).
  void _react() {
    if (_vm.shakeTick != _shake) {
      _shake = _vm.shakeTick;
      Haptics.error();
    }
    final e = _vm.error;
    if (e != null && !identical(e, _shownError) && _vm.step != RegisterStep.verification && mounted) {
      _shownError = e;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessageOf(context, e))));
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_react);
    super.dispose();
  }

  Future<void> _guest() async {
    final route = await _vm.continueAsGuest();
    if (mounted) context.go(route);
  }

  void _back() {
    if (!_vm.back()) context.popOr(Routes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<RegisterViewModel>();
    final pad = MediaQuery.paddingOf(context);
    final names = RegisterRouteBar.stopNames(context);
    final reduce = context.reduceMotion;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: p.bg,
        body: Stack(
          children: [
            Positioned(right: -120, top: -90, child: MorphBlob(size: 300, color: p.mint, opacity: .6, seed: 2)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(8, pad.top + 2, 16, 0),
                  child: Row(
                    children: [
                      AppIconButton(icon: AppIcons.back, semanticLabel: l.commonBack, iconSize: 24, onPressed: _back),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l.authRegStop(vm.stopIndex + 1, RegisterViewModel.stopCount, names[vm.stopIndex]),
                          style: AppTypography.body(13, weight: FontWeight.w900, color: p.mut),
                        ),
                      ),
                      if (vm.step != RegisterStep.verification)
                        TextButton(
                          onPressed: _guest,
                          style: TextButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: p.teal),
                          child: Text(l.authRegLater, style: AppTypography.body(14, weight: FontWeight.w900, color: p.teal)),
                        ),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(28, 8, 28, 0), child: RegisterRouteBar(index: vm.stopIndex)),
                if (vm.referralCode != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Align(alignment: Alignment.centerLeft, child: TagBadge(label: l.authRegReferral(vm.referralCode!), background: p.purS, foreground: p.purT)),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: reduce ? 300 : 450),
                    switchInCurve: onbCurve,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: reduce
                          ? child
                          : SlideTransition(position: Tween(begin: const Offset(.1, 0), end: Offset.zero).animate(a), child: child),
                    ),
                    child: SingleChildScrollView(
                      key: ValueKey(vm.step),
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                      child: _step(vm.step),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + pad.bottom), child: _cta(vm)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(RegisterStep s) => switch (s) {
        RegisterStep.identity => const IdentityStep(),
        RegisterStep.contact => const ContactStep(),
        RegisterStep.otp => const OtpStep(),
        RegisterStep.emergency => const EmergencyStep(),
        RegisterStep.agreements => const AgreementsStep(),
        RegisterStep.verification => const VerificationScene(),
        RegisterStep.underAge => UnderAgeStep(onGuest: _guest),
      };

  Widget _cta(RegisterViewModel vm) {
    final l = context.l10n;
    final label = switch (vm.step) {
      RegisterStep.otp => vm.otpState == OtpState.ok ? l.authOtpVerified : l.authOtpConfirm,
      RegisterStep.agreements => l.authLegalConfirm,
      RegisterStep.underAge => l.authParentSend,
      _ => l.commonContinue,
    };
    if (vm.step == RegisterStep.verification) {
      if (vm.verifyStatus != VerifyStatus.verified) return const SizedBox(height: 56);
      return AppButton(label: l.authSummitCta, icon: AppIcons.mountain, onPressed: () => context.go(Routes.summit));
    }
    if (vm.step == RegisterStep.underAge && (vm.underAge != UnderAgeKind.needsParent || vm.parentSent)) {
      return const SizedBox(height: 56);
    }
    return AppButton(label: label, busy: vm.busy, onPressed: vm.canContinue ? vm.next : null);
  }
}

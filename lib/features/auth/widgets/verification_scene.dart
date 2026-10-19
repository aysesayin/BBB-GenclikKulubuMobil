import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../onboarding/widgets/motion.dart';
import '../view_model/register_view_model.dart';

/// 5 · Zirve öncesi MERNİS sahnesi: kimlik kartı üzerinde tarama ışığı (1,6 sn
/// döngü), kalkan 2,6 sn'de dolar, doğrulanınca ✓ patlar.
class VerificationScene extends StatelessWidget {
  const VerificationScene({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<RegisterViewModel>();
    final status = vm.verifyStatus;
    final verified = status == VerifyStatus.verified;
    final failed = status == VerifyStatus.failed;
    final reduce = context.reduceMotion;
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 300,
          height: 186,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.sf,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.line, width: 2),
            boxShadow: p.cardShadow,
          ),
          child: Stack(
            children: [
              Positioned(left: 20, top: 26, child: _bar(p.sf2, 74, 92, 12)),
              Positioned(left: 112, top: 34, child: _bar(p.sf2, 150, 12, 6)),
              Positioned(left: 112, top: 58, child: _bar(p.sf2, 110, 12, 6)),
              Positioned(left: 112, top: 82, child: _bar(p.sf2, 130, 12, 6)),
              Positioned(left: 20, right: 20, bottom: 26, child: _bar(p.sf2, null, 14, 7)),
              if (status == VerifyStatus.running && !reduce)
                Positioned.fill(
                  child: LoopMotion(
                    duration: const Duration(milliseconds: 800),
                    builder: (_, t, _) => Align(
                      alignment: Alignment(0, -.88 + 1.64 * Curves.easeInOut.transform(t)),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(color: p.glow, boxShadow: [BoxShadow(color: p.glow, blurRadius: 22, spreadRadius: 8)]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Shield(status: status),
        const SizedBox(height: 22),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            failed ? l.authVerifyFailed : (verified ? l.authVerified : l.authVerifyTitle),
            textAlign: TextAlign.center,
            style: AppTypography.display(30, height: 1.05, color: failed ? p.errorText : p.ink),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          failed && vm.error != null ? errorMessageOf(context, vm.error!) : l.authVerifyBody,
          textAlign: TextAlign.center,
          style: AppTypography.body(14, color: p.mut, height: 1.45),
        ),
        if (failed) ...[
          const SizedBox(height: 18),
          AppButton(label: l.commonRetry, size: AppButtonSize.medium, onPressed: vm.runVerification),
          const SizedBox(height: 8),
          AppButton(label: l.authVerifyFix, variant: AppButtonVariant.outlineInk, size: AppButtonSize.medium, onPressed: vm.back),
        ],
      ],
    );
  }

  Widget _bar(Color c, double? w, double h, double r) =>
      Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));
}

class _Shield extends StatefulWidget {
  const _Shield({required this.status});

  final VerifyStatus status;

  @override
  State<_Shield> createState() => _ShieldState();
}

class _ShieldState extends State<_Shield> with SingleTickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  static const _path = 'M12 1 2 5v8c0 6.5 4.3 11.6 10 13.5 5.7-1.9 10-7 10-13.5V5z';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Shield old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      if (widget.status == VerifyStatus.verified) Haptics.medium();
      if (widget.status == VerifyStatus.failed) Haptics.error();
      _sync();
    }
  }

  void _sync() {
    switch (widget.status) {
      case VerifyStatus.verified:
        _fill.value = 1;
      case VerifyStatus.running:
        if (context.reduceMotion) {
          _fill.value = .45;
        } else {
          _fill.forward(from: 0);
        }
      case VerifyStatus.idle || VerifyStatus.failed:
        _fill.stop();
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    String svg(Color c) => '<svg viewBox="0 0 24 28"><path d="$_path" fill="${c.hex}"/></svg>';
    final failed = widget.status == VerifyStatus.failed;
    return ExcludeSemantics(
      child: SizedBox(
        width: 84,
        height: 96,
        child: Stack(
          children: [
            SvgArt(svg(p.sf2), width: 84, height: 96),
            AnimatedBuilder(
              animation: _fill,
              builder: (_, _) => ClipRect(
                clipper: _BottomClip(onbCurve.transform(_fill.value)),
                child: SvgArt(svg(failed ? p.errorText : p.successText), width: 84, height: 96),
              ),
            ),
            if (widget.status == VerifyStatus.verified)
              Positioned(
                left: 22,
                top: 26,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: context.reduceMotion ? 1 : .6, end: 1),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: AppIcon(AppIcons.check, size: 40, color: p.paper, strokeWidth: 3.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomClip extends CustomClipper<Rect> {
  _BottomClip(this.f);
  final double f;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, size.height * (1 - f), size.width, size.height);

  @override
  bool shouldReclip(_BottomClip o) => o.f != f;
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/l10n.dart';
import '../view_model/cart_view_model.dart';

/// 5 dk rezerv kartı: halka + başlık + mm:ss. Sunucu saatine göre hesaplanmış
/// [CartViewModel.deadline] kullanılır; bitişi ekran düzeyindeki zamanlayıcı da denetler.
class HoldTimerCard extends StatefulWidget {
  const HoldTimerCard({super.key, required this.vm});

  final CartViewModel vm;

  @override
  State<HoldTimerCard> createState() => _HoldTimerCardState();
}

class _HoldTimerCardState extends State<HoldTimerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = widget.vm;
    final phase = vm.phase;
    final (bg, fg, title, sub) = switch (phase) {
      HoldPhase.expired => (p.pinkS, p.pinkT, l.svcHoldExpiredTitle, l.svcHoldExpiredSub),
      HoldPhase.low => (p.pinkS, p.pinkT, l.svcHoldLowTitle, l.svcHoldLowSub),
      _ => (p.tealS, p.teal, l.svcHoldActiveTitle, l.svcHoldActiveSub),
    };
    final deadline = vm.deadline ?? vm.now();
    final timeStyle = AppTypography.display(28, color: fg).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Semantics(
      container: true,
      label: l.svcHoldTimerSemantics(title, Fmt.mmss(vm.remaining)),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.tile)),
        child: Row(
          children: [
            ProgressRing(value: vm.holdProgress, color: fg, track: fg.withValues(alpha: .2), size: 40, stroke: 5),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(liveRegion: true, child: Text(title, style: AppTypography.body(15, weight: FontWeight.w900, color: fg))),
                  Text(sub, style: AppTypography.body(12, color: fg)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CountdownText(
              key: ValueKey(deadline),
              deadline: deadline,
              now: vm.now,
              style: timeStyle,
              onFinished: vm.checkExpiry,
            ),
          ],
        ),
      ),
    );
  }
}

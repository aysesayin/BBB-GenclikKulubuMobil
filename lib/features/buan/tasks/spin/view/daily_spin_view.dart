import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../core/base/base_view.dart';
import '../../../../../core/base/view_state.dart';
import '../../../../../core/di/locator.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/daily_spin.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';
import '../../../../../l10n/l10n.dart';
import '../../widgets/ticking_countdown.dart';
import '../view_model/daily_spin_view_model.dart';
import '../widgets/shake_panel.dart';
import '../widgets/spin_parts.dart';
import '../widgets/spin_wheel.dart';

/// E7 · Günlük Şans (çark / salla).
class DailySpinView extends StatelessWidget {
  const DailySpinView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => DailySpinViewModel(sl<DailySpinRepository>())..load(), child: const _Body());
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final DailySpinViewModel _vm = context.read<DailySpinViewModel>();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChange);
  }

  void _onChange() {
    final e = _vm.error;
    if (e == null || !mounted) return;
    _vm.clearError();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessageOf(context, e))));
  }

  @override
  void dispose() {
    _vm.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<DailySpinViewModel>();
    final available = vm.status?.available ?? false;
    final won = vm.revealed;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.night,
        body: Stack(
          children: [
            Positioned(
              top: 160,
              left: -34,
              child: SvgArt(
                '<svg viewBox="0 0 460 460"><path d="M240 20c120 0 210 80 200 200s-100 220-220 210S10 330 30 210 120 20 240 20z" fill="${p.buanFill.hex}"/></svg>',
                width: 460,
                height: 460,
              ),
            ),
            Column(
              children: [
                AppBackHeader(
                  title: l.taskSpinTitle,
                  color: p.onNight,
                  trailing: [if (vm.status != null) SpinChanceChip(label: available ? l.taskSpinChanceToday : l.taskSpinChanceUsed)],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: SpinModeTabs(
                    labels: [l.taskSpinTabWheel, l.taskSpinTabShake],
                    index: vm.mode.index,
                    onChanged: (i) => vm.setMode(SpinMode.values[i]),
                  ),
                ),
                Expanded(child: _state(context, vm)),
              ],
            ),
            if (won != null) SpinWinDialog(amount: won.amount, onClose: vm.dismissResult),
            Positioned.fill(child: CelebrationOverlay(play: won != null && won.amount > 0)),
          ],
        ),
      ),
    );
  }

  Widget _state(BuildContext context, DailySpinViewModel vm) {
    final s = vm.state;
    if (s is ViewError<DailySpinStatus> && s.cached == null) {
      // Gece zemininde okunur olsun diye hata görünümü koyu temayla çizilir.
      return Theme(
        data: AppTheme.dark,
        child: ErrorStateView(error: s.error, onRetry: vm.load),
      );
    }
    return ViewStateBuilder<DailySpinStatus>(
      state: s,
      onRetry: vm.load,
      skeleton: (_) => const Shimmer(child: Center(child: SkeletonBox(width: 300, height: 300, circle: true))),
      builder: (context, data, {required offline}) => vm.mode == SpinMode.shake && data.available && vm.pendingResult == null
          ? ShakePanel(enabled: vm.canSpin, onShake: vm.spin)
          : _WheelBody(vm: vm, data: data),
    );
  }
}

class _WheelBody extends StatelessWidget {
  const _WheelBody({required this.vm, required this.data});

  final DailySpinViewModel vm;
  final DailySpinStatus data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final locked = !data.available && !vm.spinning;
    final next = data.nextSpinAt;
    final onNight = AppTypography.body(14, color: p.onNight.withValues(alpha: .9));
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 24, 36, 8),
            child: SpinWheel(
              slices: data.slices,
              targetIndex: vm.pendingResult?.sliceIndex,
              onEnd: vm.onSpinAnimationEnd,
              semanticLabel: l.taskSpinWheelSemantics,
              dimmed: locked,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 44 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            children: [
              if (!locked)
                Text(l.taskSpinDailyNote, textAlign: TextAlign.center, style: onNight)
              else ...[
                Semantics(
                  header: true,
                  child: Text(
                    l.taskSpinLockedTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.display(20, color: p.onNight),
                  ),
                ),
                if (data.lastAmount case final a? when a > 0) ...[
                  const SizedBox(height: 4),
                  Text(l.taskSpinLockedWon(l.buanAmount(Fmt.signed(a))), textAlign: TextAlign.center, style: onNight),
                ],
                if (next != null) ...[
                  const SizedBox(height: 4),
                  TickingCountdown(
                    deadline: next,
                    onFinished: vm.load,
                    builder: (_, hms) => Text(l.taskSpinNextIn(hms), style: AppTypography.number(15, color: p.glow)),
                  ),
                ],
              ],
              const SizedBox(height: 10),
              AppButton(
                label: vm.spinning ? l.taskSpinSpinning : l.taskSpinCta,
                busy: vm.spinning && vm.pendingResult == null,
                onPressed: vm.canSpin ? vm.spin : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

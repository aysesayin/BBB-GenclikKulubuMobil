import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../../core/base/base_view.dart';
import '../../../../../core/di/locator.dart';
import '../../../../../core/storage/cache_store.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/steps.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';
import '../../../../../l10n/l10n.dart';
import '../view_model/step_source.dart';
import '../view_model/steps_view_model.dart';
import '../widgets/steps_parts.dart';
import '../widgets/steps_week_chart.dart';

/// E9 · Bir Adım At.
class StepsView extends StatelessWidget {
  const StepsView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => StepsViewModel(sl<StepsRepository>(), sensor: const PedometerStepSensor(), tracker: StepTracker.cache(sl<CacheStore>()))..start(),
    child: const _Body(),
  );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final StepsViewModel _vm = context.read<StepsViewModel>();
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onVm);
  }

  void _onVm() {
    if (!mounted) return;
    final award = _vm.takeAward();
    if (award > 0) {
      setState(() => _celebrate = true);
      showRewardToast(context, label: context.l10n.taskStepsToast, amount: award);
    }
    if (_vm.error case final e?) {
      _vm.clearError();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessageOf(context, e))));
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final vm = context.watch<StepsViewModel>();
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Blob(shape: BlobShape.f, color: p.grnS),
          ),
          ViewStateBuilder<StepsSummary>(
            state: vm.state,
            onRetry: vm.load,
            skeleton: (_) => const Shimmer(child: Center(child: SkeletonBox(width: 250, height: 250, circle: true))),
            builder: (context, s, {required offline}) => _Content(vm: vm, summary: s, offline: offline),
          ),
          Positioned.fill(child: CelebrationOverlay(play: _celebrate)),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.vm, required this.summary, required this.offline});

  final StepsViewModel vm;
  final StepsSummary summary;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final sensorOff = vm.sensorState == StepSensorState.denied || vm.sensorState == StepSensorState.unavailable;
    final km = Fmt.number(double.parse(vm.distanceKm.toStringAsFixed(1)));
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              AppBackHeader(
                title: l.taskStepsTitle,
                trailing: [BuanPointsBadge(points: summary.reward, minWidth: 70, height: 32)],
              ),
              if (offline) const OfflineBanner(),
              const SizedBox(height: 18),
              Center(
                child: StepsGoalRing(steps: vm.todaySteps, goal: summary.goal, progress: vm.progress),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StepsStatChip(label: l.taskStepsKm(km)),
                  const SizedBox(width: 10),
                  StepsStatChip(label: l.taskStepsActive(vm.activeMinutes)),
                ],
              ),
              if (sensorOff)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: StepsSensorNotice(
                    denied: vm.sensorState == StepSensorState.denied,
                    onSettings: kIsWeb ? null : openAppSettings,
                    onRetry: vm.retrySensor,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: StepsWeekChart(
                  days: [for (final d in summary.week) (d.date, d.steps), (summary.date, vm.todaySteps)],
                  goal: summary.goal,
                  goalDays: vm.goalDays,
                  targetDays: summary.weeklyTargetDays,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 40 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            children: [
              if (vm.syncedAt case final at?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    l.taskStepsSynced(_ago(l, at)),
                    style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
                  ),
                ),
              AppButton(
                label: vm.claimed
                    ? l.taskStepsClaimed
                    : vm.reached
                    ? l.taskStepsClaim(Fmt.number(summary.reward))
                    : l.taskStepsRemaining(Fmt.number(vm.remaining)),
                busy: vm.syncing,
                onPressed: vm.reached && !vm.claimed && !vm.syncing ? vm.claim : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _ago(AppLocalizations l, DateTime at) {
    final m = DateTime.now().difference(at).inMinutes;
    return m < 1 ? l.taskStepsSyncedNow : l.taskStepsMinutesAgo(m);
  }
}

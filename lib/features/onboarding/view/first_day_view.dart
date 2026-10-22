import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/auth/first_day_task.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/first_day_view_model.dart';
import '../widgets/first_day_task_card.dart';

/// A9 · "İlk günün": 3 görevlik kontrol listesi; her satır dokunulabilir kart + BUAN rozeti.
/// Alt buton "Keşfet'e geç" onboarding'i kapatır.
class FirstDayView extends StatelessWidget {
  const FirstDayView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => FirstDayViewModel(sl<AuthRepository>(), sl<SessionController>())..load(),
        child: const FirstDayBody(),
      );
}

/// Testlerde sağlayıcıyla doğrudan sarılabilir.
class FirstDayBody extends StatelessWidget {
  const FirstDayBody({super.key});

  Future<void> _open(BuildContext context, FirstDayViewModel vm, FirstDayTask task) async {
    Haptics.selection();
    final route = await vm.open(task);
    if (!context.mounted) return;
    if (FirstDayViewModel.isTabRoute(route)) {
      context.go(route);
    } else {
      await context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<FirstDayViewModel>();
    final pad = MediaQuery.paddingOf(context);
    final easy = context.easyMode;
    return Scaffold(
      backgroundColor: p.bg,
      body: BlobBackground(
        variant: easy ? BlobLayout.none : BlobLayout.explore,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, pad.top + 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l.onbFirstDayTitle, style: AppTypography.display(easy ? 34 : 40, height: 1, color: p.ink)),
                    ),
                  ),
                  Mascot(mood: vm.allDone ? MascotMood.celebrate : MascotMood.happy, size: 64),
                ],
              ),
            ),
            Expanded(
              child: ViewStateBuilder<List<FirstDayTask>>(
                state: vm.state,
                onRetry: vm.refresh,
                skeleton: (_) => const _Skeleton(),
                empty: (_) => EmptyState(title: l.onbFirstDayEmpty, message: l.onbFirstDaySub),
                builder: (context, tasks, {required offline}) => ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  children: [
                    if (offline) const Padding(padding: EdgeInsets.only(bottom: 12), child: OfflineBanner()),
                    _Header(vm: vm, count: tasks.length),
                    const SizedBox(height: 16),
                    for (final t in tasks) ...[
                      FirstDayTaskCard(task: t, done: vm.isDone(t.id), onTap: () => _open(context, vm, t)),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + pad.bottom),
              child: AppButton(
                label: l.onbFirstDayGo,
                icon: AppIcons.compass,
                onPressed: () async {
                  final route = await vm.finish();
                  if (context.mounted) context.go(route);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Bugün 3 şey yap, 2.600 BUAN kazan" + ilerleme çubuğu (mor BUAN kartı).
class _Header extends StatelessWidget {
  const _Header({required this.vm, required this.count});

  final FirstDayViewModel vm;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final progress = count == 0 ? 0.0 : vm.doneCount / count;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: p.buanGradient,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [BoxShadow(color: p.buanShadow.withValues(alpha: .35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.onbFirstDayHeader(count, Fmt.number(vm.totalReward)),
            style: AppTypography.display(22, height: 1.1, color: p.onBuan),
          ),
          const SizedBox(height: 6),
          Text(l.onbFirstDaySub, style: AppTypography.body(13, height: 1.35, color: p.onBuan.withValues(alpha: .85))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppProgressBar(
                  value: progress,
                  color: p.coinMark,
                  track: p.onBuan.withValues(alpha: .22),
                  semanticsValue: l.onbFirstDayProgress(vm.doneCount, count),
                ),
              ),
              const SizedBox(width: 10),
              ExcludeSemantics(child: Text(l.onbFirstDayProgress(vm.doneCount, count), style: AppTypography.number(13, color: p.onBuan))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          children: const [
            SkeletonBox(height: 116, radius: AppRadii.card),
            SizedBox(height: 16),
            SkeletonBox(height: 84, radius: AppRadii.lg),
            SizedBox(height: 12),
            SkeletonBox(height: 84, radius: AppRadii.lg),
            SizedBox(height: 12),
            SkeletonBox(height: 84, radius: AppRadii.lg),
          ],
        ),
      );
}

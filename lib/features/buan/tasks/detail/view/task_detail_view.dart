import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/base/base_view.dart';
import '../../../../../core/base/view_state.dart';
import '../../../../../core/di/locator.dart';
import '../../../../../core/network/app_exception.dart';
import '../../../../../core/router/routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan/buan_task.dart';
import '../../../../../data/repositories/buan_repository.dart';
import '../../../../../l10n/l10n.dart';
import '../../../widgets/buan_skeleton.dart';
import '../view_model/task_detail_view_model.dart';
import '../widgets/task_detail_parts.dart';

/// E13 · Genel görev detayı — kendi akışı olmayan görevler (`/buan/gorev/:id`).
class TaskDetailView extends StatelessWidget {
  const TaskDetailView({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    key: ValueKey(taskId),
    create: (_) => TaskDetailViewModel(sl<BuanRepository>(), taskId: taskId)..load(),
    child: const _Body(),
  );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final TaskDetailViewModel _vm = context.read<TaskDetailViewModel>();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onVm);
  }

  void _onVm() {
    if (!mounted) return;
    if (_vm.error case final e?) {
      _vm.clearError();
      _snack(errorMessageOf(context, e));
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _complete() async {
    final l = context.l10n;
    final action = _vm.primaryAction;
    final ok = await _vm.complete();
    if (!ok || !mounted) return;
    Haptics.medium();
    _snack(action == TaskPrimaryAction.declare ? l.buanTaskDeclaredToast : l.buanTaskAppliedToast);
  }

  Future<void> _openBiko() async {
    var ok = false;
    try {
      ok = await launchUrl(_vm.bikoUri, mode: LaunchMode.externalApplication);
    } on Exception {
      ok = false;
    }
    if (!ok && mounted) _snack(context.l10n.buanTaskBikoFail);
  }

  void _primary() {
    switch (_vm.primaryAction) {
      case TaskPrimaryAction.declare || TaskPrimaryAction.apply:
        _complete();
      case TaskPrimaryAction.openBiko:
        _openBiko();
      case TaskPrimaryAction.openIdea:
        context.push(TaskDetailViewModel.ideaRoute);
      case TaskPrimaryAction.openOpportunities:
        context.go(Routes.opportunities);
      case TaskPrimaryAction.none:
        break;
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskDetailViewModel>();
    final l = context.l10n;
    final p = context.palette;
    final isNotFound = vm.state is ViewError<BuanTask> && (vm.state as ViewError<BuanTask>).error is NotFoundException;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppBackHeader(title: vm.task?.title ?? l.buanTabEarn, titleSize: 24),
          Expanded(
            child: isNotFound
                ? EmptyState(title: l.buanTaskNotFoundTitle, message: l.buanTaskNotFoundMessage)
                : ViewStateBuilder<BuanTask>(
                    state: vm.state,
                    onRetry: vm.load,
                    skeleton: (_) =>
                        MediaQuery.removePadding(context: context, removeTop: true, child: const BuanSkeleton(rows: 4, rowHeight: 90)),
                    builder: (context, task, {required offline}) => _Content(task: task, offline: offline, onPrimary: _primary),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.task, required this.offline, required this.onPrimary});

  final BuanTask task;
  final bool offline;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskDetailViewModel>();
    final l = context.l10n;
    final action = vm.primaryAction;
    final cta = switch (action) {
      TaskPrimaryAction.declare => l.buanTaskFollowCta,
      TaskPrimaryAction.apply => l.buanTaskVolunteerCta,
      TaskPrimaryAction.openBiko => l.buanTaskBikoCta,
      TaskPrimaryAction.openIdea => l.buanTaskIdeaCta,
      TaskPrimaryAction.openOpportunities => l.buanEarnSheetOpportunities,
      TaskPrimaryAction.none => null,
    };
    final hint = switch (action) {
      TaskPrimaryAction.declare => l.buanTaskFollowHint,
      TaskPrimaryAction.openBiko => l.buanTaskBikoHint,
      _ => null,
    };
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (offline) const OfflineBanner(margin: EdgeInsets.only(bottom: 12)),
              TaskDetailHeader(task: task),
              const SizedBox(height: 14),
              TaskStatusBox(task: task, hint: hint),
              if (task.frequency case final f? when f.isNotEmpty) ...[
                const SizedBox(height: 12),
                TaskFrequencyLine(frequency: f),
              ],
              if (task.steps.isNotEmpty) ...[
                const SizedBox(height: 20),
                TaskSection(title: l.buanTaskDetailSteps, children: [for (var i = 0; i < task.steps.length; i++) TaskStepRow(index: i + 1, text: task.steps[i])]),
              ],
              if (task.rules.isNotEmpty) ...[
                const SizedBox(height: 20),
                TaskSection(title: l.buanEarnSheetRules, children: [for (final r in task.rules) TaskRuleRow(text: r)]),
              ],
            ],
          ),
        ),
        if (cta != null)
          StickyBottomBar(
            child: action == TaskPrimaryAction.openBiko
                ? AppButton(label: cta, icon: AppIcons.share, onPressed: vm.submitting ? null : onPrimary)
                : AppButton.buan(label: cta, busy: vm.submitting, onPressed: vm.submitting ? null : onPrimary),
          ),
      ],
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/base/base_view.dart';
import '../../../../../core/di/locator.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/quiz.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';
import '../../../../../l10n/l10n.dart';
import '../view_model/quiz_view_model.dart';
import '../widgets/quiz_parts.dart';
import '../widgets/quiz_summary.dart';

/// E10 · Cevapla Kazan.
class QuizView extends StatelessWidget {
  const QuizView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(create: (_) => QuizViewModel(sl<QuizRepository>())..load(), child: const _Body());
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final QuizViewModel _vm = context.read<QuizViewModel>();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onVm);
  }

  void _onVm() {
    if (!mounted) return;
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
    final vm = context.watch<QuizViewModel>();
    final l = context.l10n;
    return Scaffold(
      body: ViewStateBuilder<Quiz?>(
        state: vm.state,
        onRetry: vm.load,
        skeleton: (_) => const _Skeleton(),
        empty: (_) => Column(
          children: [
            AppBackHeader(title: l.taskQuizTitle),
            Expanded(
              child: EmptyState(
                title: l.taskQuizEmptyTitle,
                message: l.taskQuizEmptyBody(vm.quiz?.weeklyLimit ?? 2),
                ctaLabel: l.commonBack,
                onCta: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
        builder: (context, quiz, {required offline}) => quiz == null
            ? const SizedBox.shrink()
            : vm.finished
            ? QuizSummary(correct: vm.correctCount, total: vm.total, awarded: vm.awardedTotal)
            : _Question(vm: vm, quiz: quiz),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.vm, required this.quiz});

  final QuizViewModel vm;
  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final q = vm.question!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 20, 0),
          child: Row(
            children: [
              AppIconButton(icon: AppIcons.close, semanticLabel: l.commonClose, onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l.taskQuizProgress(quiz.title, vm.index + 1, vm.total),
                    style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
                  ),
                ),
              ),
              BuanPointsBadge(points: quiz.reward, height: 32),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: QuizTimerBar(key: ValueKey(q.id), seconds: quiz.timeLimitSec, stopped: vm.answered || vm.submitting, onTimeUp: vm.timeUp),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            children: [
              AppCard(
                radius: AppRadii.xl,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (q.imageUrl case final url?)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(imageUrl: url, height: 130, fit: BoxFit.cover, errorWidget: (_, _, _) => const QuizIllustration()),
                      )
                    else
                      const QuizIllustration(),
                    const SizedBox(height: 16),
                    Text(q.text, style: AppTypography.display(24, height: 1.15, color: p.ink)),
                    const SizedBox(height: 16),
                    _Options(vm: vm, question: q),
                  ],
                ),
              ),
              if (vm.answered) ...[const SizedBox(height: 16), QuizFeedback(text: _feedback(l), correct: vm.isCorrect)],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 40 + MediaQuery.paddingOf(context).bottom),
          child: AppButton(label: vm.isLast ? l.taskQuizFinish : l.taskQuizNext, onPressed: vm.answered ? vm.next : null),
        ),
      ],
    );
  }

  String _feedback(AppLocalizations l) {
    final r = vm.result!;
    final info = r.explanation;
    if (vm.isCorrect) {
      final amount = l.buanAmount(Fmt.signed(r.awarded));
      return info == null || info.isEmpty ? l.taskQuizFeedbackCorrect(amount) : l.taskQuizFeedbackCorrectInfo(info, amount);
    }
    final answer = vm.correctLabel ?? '';
    final base = vm.timedOut ? l.taskQuizTimeUp(answer) : l.taskQuizFeedbackWrong(answer);
    return info == null || info.isEmpty ? base : '$base $info';
  }
}

class _Options extends StatelessWidget {
  const _Options({required this.vm, required this.question});

  final QuizViewModel vm;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final opts = question.options;
    final locked = vm.answered || vm.submitting;
    Widget cell(QuizOption o) =>
        QuizOptionButton(label: o.label, mark: vm.markOf(o.id), selected: vm.picked == o.id, onTap: locked ? null : () => vm.answer(o.id));
    return Column(
      children: [
        for (var i = 0; i < opts.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cell(opts[i])),
              const SizedBox(width: 10),
              Expanded(child: i + 1 < opts.length ? cell(opts[i + 1]) : const SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 64, 20, 0),
      children: const [
        SkeletonBox(height: 10),
        SizedBox(height: 24),
        SkeletonBox(height: 130, radius: 20),
        SizedBox(height: 16),
        SkeletonBox(height: 28),
        SizedBox(height: 16),
        SkeletonBox(height: 64, radius: 20),
        SizedBox(height: 10),
        SkeletonBox(height: 64, radius: 20),
      ],
    ),
  );
}

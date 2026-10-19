import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/profile/child_profile.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/profile_ui.dart';
import '../view_model/children_view_model.dart';
import '../widgets/child_input_formatters.dart';
import '../widgets/child_tile.dart';

/// I4 · Çocuk İşlemleri (tam ekran).
class ChildrenView extends StatelessWidget {
  const ChildrenView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => ChildrenViewModel(sl<ProfileRepository>())..load(), child: const _Body());
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _tckn = TextEditingController();
  final _birth = TextEditingController();

  @override
  void dispose() {
    _tckn.dispose();
    _birth.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<ChildrenViewModel>();
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    final child = await vm.add(tckn: _tckn.text, birthDate: _birth.text);
    if (child == null || !mounted) return;
    // KVKK: başarıdan sonra TCKN alanda bile kalmaz.
    _tckn.clear();
    _birth.clear();
    Haptics.medium();
    showProfileSnack(context, l.profileChildAdded(child.displayName));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChildrenViewModel>();
    final l = context.l10n;
    final hasData = vm.state.dataOrNull != null;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: l.profileChildrenTitle),
          Expanded(
            child: ViewStateBuilder<List<ChildProfile>>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const ProfileListSkeleton(blocks: [76, 76, 320]),
              builder: (context, kids, {required offline}) => _content(context, vm, kids, offline: offline),
            ),
          ),
          if (hasData)
            BottomCtaBar(
              child: AppButton(label: l.profileChildSubmit, busy: vm.submitting, onPressed: _submit),
            ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, ChildrenViewModel vm, List<ChildProfile> kids, {required bool offline}) {
    final p = context.palette;
    final l = context.l10n;
    final tcknIssue = vm.tcknIssue;
    final dateError = vm.dateInvalid ? l.profileErrDate : (vm.dateFuture ? l.profileChildFutureDate : null);
    final alert = switch (vm.issue) {
      ChildFormIssue.overAge => l.profileChildOverAge,
      ChildFormIssue.mernisFailed => l.profileChildMernisFailed,
      ChildFormIssue.alreadyAdded => l.profileChildAlreadyAdded,
      null => vm.error == null ? null : errorMessageOf(context, vm.error!),
    };
    return ListView(
      children: [
        if (offline) const OfflineBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Text(l.profileChildrenIntro, style: AppTypography.body(14, color: p.mut)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (kids.isEmpty) Text(l.profileChildrenEmpty, style: AppTypography.body(14, color: p.mut)),
              for (var i = 0; i < kids.length; i++) ...[if (i > 0) const SizedBox(height: 10), ChildTile(child: kids[i], index: i)],
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.card)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(l.profileChildAddTitle, style: AppTypography.display(20, color: p.ink)),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l.profileChildTckn,
                controller: _tckn,
                keyboardType: TextInputType.number,
                inputFormatters: const [
                  GroupedDigitsFormatter([3, 3, 3, 2]),
                ],
                letterSpacing: 1,
                textInputAction: TextInputAction.next,
                errorText: tcknIssue == null ? null : validationText(l, tcknIssue),
                onChanged: (_) => vm.clearIssues(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l.profileChildBirth,
                controller: _birth,
                hint: l.profileChildBirthHint,
                keyboardType: TextInputType.number,
                inputFormatters: const [DateDotsFormatter()],
                textInputAction: TextInputAction.done,
                errorText: dateError,
                onChanged: (_) => vm.clearIssues(),
                onSubmitted: (_) => _submit(),
              ),
              if (alert != null) ...[const SizedBox(height: 14), InlineAlert(alert)],
              const SizedBox(height: 14),
              Text(l.profileChildNote, style: AppTypography.body(12, color: p.mut)),
            ],
          ),
        ),
      ],
    );
  }
}

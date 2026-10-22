import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/rating_view_model.dart';
import 'opp_icons.dart';

/// Kod kullanıldıktan sonra açılan puanlama alt sayfası: 1–5 yıldız + isteğe bağlı yorum.
/// Başarıda [RatingResult] ile kapanır; çağıran toast'ı gösterir.
class RatingSheet extends StatelessWidget {
  const RatingSheet({super.key, required this.opportunityId});

  final String opportunityId;

  static Future<RatingResult?> show(BuildContext context, {required String opportunityId}) =>
      AppSheet.show<RatingResult>(context, builder: (_) => RatingSheet(opportunityId: opportunityId));

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => RatingViewModel(sl<OpportunityRepository>(), opportunityId),
    child: const _Body(),
  );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  AppException? _error;

  Future<void> _submit() async {
    final vm = context.read<RatingViewModel>();
    final error = await vm.submit();
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      Haptics.error();
      return;
    }
    Navigator.of(context).pop(vm.result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RatingViewModel>();
    final p = context.palette;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(l.oppRatingTitle, textAlign: TextAlign.center, style: AppTypography.display(24, color: p.ink)),
        ),
        const SizedBox(height: 4),
        Text(l.oppRatingSubtitle, textAlign: TextAlign.center, style: AppTypography.body(14, weight: FontWeight.w800, color: p.mut)),
        const SizedBox(height: 16),
        StarRow(value: vm.stars, onChanged: vm.setStars),
        const SizedBox(height: 16),
        AppTextField(
          label: l.oppRatingComment,
          hint: l.oppRatingCommentHint,
          maxLines: 3,
          onChanged: vm.setComment,
          textInputAction: TextInputAction.done,
        ),
        if (_error case final e?) ...[
          const SizedBox(height: 10),
          Text(errorMessageOf(context, e), style: AppTypography.body(13, weight: FontWeight.w800, color: p.pinkT)),
        ],
        const SizedBox(height: 16),
        AppButton(label: l.oppRatingSubmit, busy: vm.submitting, onPressed: vm.canSubmit ? _submit : null),
      ],
    );
  }
}

/// 5 yıldız; her biri 48 px dokunma hedefi, seçili → sarı dolgu.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= RatingViewModel.maxStars; i++)
          Semantics(
            button: true,
            selected: i <= value,
            label: l.oppRatingStar(i),
            excludeSemantics: true,
            child: InkResponse(
              radius: 24,
              onTap: () {
                Haptics.selection();
                onChanged(i);
              },
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: AppIcon(
                    OppIcons.star,
                    size: 34,
                    color: i <= value ? p.cta : p.line,
                    fill: i <= value ? p.cta : null,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

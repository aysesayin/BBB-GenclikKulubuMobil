import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/profile_ui.dart';
import '../view_model/coupons_view_model.dart';

/// Kupon kodu alanı + "Ekle" butonu (52 px).
class CouponCodeForm extends StatefulWidget {
  const CouponCodeForm({super.key});

  @override
  State<CouponCodeForm> createState() => _CouponCodeFormState();
}

class _CouponCodeFormState extends State<CouponCodeForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<CouponsViewModel>();
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    final coupon = await vm.redeem(_code.text);
    if (coupon == null || !mounted) return;
    _code.clear();
    Haptics.medium();
    showProfileSnack(context, l.profileCouponAdded(coupon.title));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CouponsViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final message = switch (vm.issue) {
      CouponIssue.emptyCode => l.profileCouponEmptyCode,
      CouponIssue.invalid => l.profileCouponInvalid,
      CouponIssue.alreadyAdded => l.profileCouponAlreadyAdded,
      null => vm.error == null ? null : errorMessageOf(context, vm.error!),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  label: l.profileCouponCodeLabel,
                  textField: true,
                  child: TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-zÇĞİÖŞÜçğıöşü\- ]')),
                      LengthLimitingTextInputFormatter(24),
                    ],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => vm.clearIssue(),
                    onSubmitted: (_) => _submit(),
                    style: AppTypography.body(16, weight: FontWeight.w800, color: p.ink),
                    decoration: InputDecoration(
                      hintText: l.profileCouponCodeHint,
                      constraints: const BoxConstraints(minHeight: 52),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                      errorText: message == null ? null : '',
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                child: Material(
                  color: p.ink,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: InkWell(
                    onTap: vm.redeeming ? null : _submit,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      child: vm.redeeming
                          ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 3, color: p.bg))
                          : Text(
                              l.profileCouponAdd,
                              style: AppTypography.body(15, weight: FontWeight.w900, color: p.bg),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (message != null) ...[const SizedBox(height: 10), InlineAlert(message)],
        ],
      ),
    );
  }
}

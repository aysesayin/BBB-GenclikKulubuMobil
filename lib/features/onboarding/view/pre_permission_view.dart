import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../view_model/pre_permission_view_model.dart';

/// A7b · Bildirim ön-izin: maskot + iki sade cümle, "Devam" / "Şimdi değil".
/// Kart destesinden önce gelir; OS istemi burada açılmaz.
class PrePermissionView extends StatelessWidget {
  const PrePermissionView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => PrePermissionViewModel(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final vm = context.read<PrePermissionViewModel>();
    final pad = MediaQuery.paddingOf(context);
    final easy = context.easyMode;
    return Scaffold(
      backgroundColor: p.bg,
      body: BlobBackground(
        variant: easy ? BlobLayout.none : BlobLayout.cornerMint,
        // Sığmazsa (küçük ekran / büyük yazı) kaydırılır; sığıyorsa Spacer'lar dikeyde ortalar.
        child: LayoutBuilder(
          builder: (_, c) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, pad.top + 16, 24, 24 + pad.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - pad.top - pad.bottom - 40),
              child: IntrinsicHeight(
                child: _Content(vm: vm, easy: easy),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.vm, required this.easy});

  final PrePermissionViewModel vm;
  final bool easy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Mascot(mood: MascotMood.happy, size: easy ? 110 : 136, motion: MascotMotion.float),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            l.onbPrePermTitle,
            textAlign: TextAlign.center,
            style: AppTypography.display(easy ? 32 : 38, color: p.ink),
          ),
        ),
        const SizedBox(height: 20),
        _Reason(icon: AppIcons.flame, color: p.hotFill, iconColor: p.onHot, text: l.onbPrePermLine1),
        const SizedBox(height: 12),
        _Reason(icon: AppIcons.tag, color: p.tile2, iconColor: p.onTile, text: l.onbPrePermLine2),
        const SizedBox(height: 18),
        Text(
          l.onbPrePermBody,
          textAlign: TextAlign.center,
          style: AppTypography.body(easy ? 16 : 14, height: 1.45, color: p.mut),
        ),
        const Spacer(),
        AppButton(
          label: l.onbPrePermContinue,
          icon: AppIcons.bell,
          onPressed: () {
            Haptics.light();
            context.go(vm.continueRoute);
          },
        ),
        const SizedBox(height: 6),
        AppButton.text(
          label: l.onbPrePermNotNow,
          size: easy ? AppButtonSize.large : AppButtonSize.medium,
          onPressed: () => context.go(vm.skipRoute),
        ),
      ],
    );
  }
}

/// Tek satırlık gerekçe: renkli ikon karosu + kalın metin.
class _Reason extends StatelessWidget {
  const _Reason({required this.icon, required this.color, required this.iconColor, required this.text});

  final String icon;
  final Color color, iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadii.md)),
            child: AppIcon(icon, size: 22, color: iconColor, strokeWidth: 2.4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(16, weight: FontWeight.w900, height: 1.3, color: p.ink),
            ),
          ),
        ],
      ),
    );
  }
}

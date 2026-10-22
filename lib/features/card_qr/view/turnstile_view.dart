import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../l10n/l10n.dart';
import '../../opportunities/widgets/ticket_parts.dart';
import '../utils/brightness_boost.dart';
import '../view_model/card_view_model.dart';

/// D1b · Turnike / gişe modu (`/kartim/turnike`): koyu tam ekran, parlaklık %100,
/// dev QR (≥ 260 px), 48 px 4 haneli kod, yenileme halkası, tek "Kapat" butonu.
/// 2 dakika sonra kendiliğinden kapanır.
class TurnstileView extends StatelessWidget {
  const TurnstileView({super.key, this.autoClose = autoCloseDefault});

  static const autoCloseDefault = Duration(minutes: 2);

  final Duration autoClose;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => CardViewModel(sl<CardRepository>())..load(),
    child: _Body(autoClose: autoClose),
  );
}

class _Body extends StatefulWidget {
  const _Body({required this.autoClose});

  final Duration autoClose;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _boost = BrightnessBoost();
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_boost.enable());
    _closeTimer = Timer(widget.autoClose, _close);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CardViewModel>().setActive(true);
    });
  }

  /// Derin bağlantıyla açıldıysa (geri dönülecek sayfa yok) Kartım sekmesine gider.
  void _close() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.card);
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _boost.restore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CardViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final token = vm.token?.token;
    final pin = vm.pin;
    return Scaffold(
      backgroundColor: p.onTile,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            children: [
              Semantics(
                header: true,
                child: Text(l.cardTurnstileTitle, style: AppTypography.display(24, color: p.paper)),
              ),
              const SizedBox(height: 4),
              Text(
                l.cardTurnstileHint,
                textAlign: TextAlign.center,
                style: AppTypography.body(14, weight: FontWeight.w800, color: p.paper.withValues(alpha: .75)),
              ),
              const Spacer(),
              LayoutBuilder(
                builder: (context, c) {
                  final size = math.max(260.0, math.min(c.maxWidth - 32, 340.0));
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(AppRadii.card)),
                    child: SizedBox.square(
                      dimension: size,
                      child: token != null
                          ? Semantics(
                              label: l.cardQrSemantics,
                              image: true,
                              excludeSemantics: true,
                              child: QrImageView(
                                data: token,
                                size: size,
                                padding: EdgeInsets.zero,
                                backgroundColor: p.paper,
                                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: p.onTile),
                                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: p.onTile),
                              ),
                            )
                          : Center(
                              child: vm.tokenLoading
                                  ? CircularProgressIndicator(color: p.onTile)
                                  : Text(
                                      vm.offline ? l.cardOfflineQr : l.cardTokenError,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.body(14, weight: FontWeight.w800, color: p.onTile),
                                    ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              if (pin != null)
                Semantics(
                  label: l.cardPinSemantics(spellOut(pin)),
                  excludeSemantics: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _DarkPin(code: pin),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProgressRing(value: vm.ringValue, color: p.cta, size: 32, stroke: 4, track: p.paper.withValues(alpha: .2)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      l.cardRefreshIn(vm.secondsLeft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(14, weight: FontWeight.w800, color: p.paper),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l.cardTurnstileAutoClose(widget.autoClose.inMinutes),
                style: AppTypography.body(12, weight: FontWeight.w700, color: p.paper.withValues(alpha: .6)),
              ),
              const Spacer(),
              AppButton(label: l.commonClose, variant: AppButtonVariant.cta, onPressed: _close),
            ],
          ),
        ),
      ),
    );
  }
}

/// Koyu zeminde 48 px kod kutucukları (beyaz kutu, ink rakam).
class _DarkPin extends StatelessWidget {
  const _DarkPin({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < code.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(minWidth: 60),
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Text(code[i], style: AppTypography.display(48, height: 1, color: p.onTile)),
          ),
        ],
      ],
    );
  }
}

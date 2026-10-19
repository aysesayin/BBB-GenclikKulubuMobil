import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../l10n/l10n.dart';
import '../utils/geo.dart';
import '../view_model/qr_scan_view_model.dart';
import '../widgets/card_icons.dart';
import '../widgets/scan_camera.dart';
import '../widgets/scan_result_sheet.dart';
import '../widgets/scan_viewfinder.dart';

/// D2 · QR Okut Kazan (tam ekran, `/qr-okut`).
class QrScanView extends StatelessWidget {
  const QrScanView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => QrScanViewModel(sl<CardRepository>(), locate: currentGeoIfPermitted),
    child: const _Body(),
  );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  /// Mock modunda vizöre dokunmak bu demo jetonuyla taramayı simüle eder.
  static const _demoToken = 'GKQR.plc-asik-veysel-gm.demo';

  final _camera = MobileScannerController(formats: const [BarcodeFormat.qrCode], detectionSpeed: DetectionSpeed.noDuplicates);

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    final vm = context.read<QrScanViewModel>();
    try {
      await _camera.toggleTorch();
      vm.setTorch(!vm.torch);
    } on Object {
      vm.setTorch(false);
    }
  }

  Future<void> _fromGallery() async {
    final vm = context.read<QrScanViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final noQr = context.l10n.cardScanNoQr;
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final capture = await _camera.analyzeImage(file.path);
      final code = capture?.barcodes.firstOrNull?.rawValue;
      if (code == null) {
        messenger.showSnackBar(SnackBar(content: Text(noQr)));
        return;
      }
      await vm.onCode(code);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(noQr)));
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.card);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QrScanViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final mq = MediaQuery.of(context);
    final glass = p.paper.withValues(alpha: .16);
    final demo = ApiConfig.useMock;
    return Scaffold(
      backgroundColor: p.night,
      body: Stack(
        children: [
          Positioned.fill(
            child: kIsWeb && demo ? const ScanBackdrop() : ScanCamera(controller: _camera, onDetect: vm.onCode),
          ),
          Positioned.fill(
            child: IgnorePointer(child: ColoredBox(color: p.night.withValues(alpha: .45))),
          ),
          Positioned(
            top: mq.padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                AppIconButton(
                  icon: AppIcons.close,
                  semanticLabel: l.commonClose,
                  size: 48,
                  background: glass,
                  color: p.paper,
                  onPressed: _close,
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.cardScanTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.display(20, color: p.onNight),
                    ),
                  ),
                ),
                Semantics(
                  toggled: vm.torch,
                  child: AppIconButton(
                    icon: CardIcons.torch,
                    semanticLabel: l.cardTorch,
                    size: 48,
                    background: vm.torch ? p.cta : glass,
                    color: vm.torch ? p.onTile : p.paper,
                    onPressed: _toggleTorch,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0, -.2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScanViewfinder(
                  semanticLabel: demo ? l.cardViewfinderDemo : l.cardViewfinder,
                  onTap: demo ? () => vm.onCode(_demoToken) : null,
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        l.cardScanHint,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(18, weight: FontWeight.w900, color: p.onNight),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.cardScanDesc,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(14, weight: FontWeight.w600, color: p.onNight),
                      ),
                      if (demo) ...[
                        const SizedBox(height: 8),
                        Text(
                          l.cardScanDemoHint,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(12, weight: FontWeight.w800, color: p.glow),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: mq.padding.bottom + 24,
            child: Row(
              children: [
                Expanded(
                  child: _GlassButton(label: l.offlineShowCard, icon: CardIcons.qrSmall, onTap: () => context.go(Routes.card)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GlassButton(label: l.cardFromGallery, icon: CardIcons.gallery, onTap: _fromGallery),
                ),
              ],
            ),
          ),
          if (vm.phase == ScanPhase.submitting)
            Positioned.fill(
              child: ColoredBox(
                color: p.night.withValues(alpha: .4),
                child: Center(
                  child: CircularProgressIndicator(color: p.glow, semanticsLabel: l.cardScanSending),
                ),
              ),
            ),
          if (vm.phase == ScanPhase.success && vm.result != null)
            Positioned.fill(
              child: ScanSheetFrame(
                coins: true,
                child: ScanSuccessContent(result: vm.result!, onDone: () => context.go(Routes.buan)),
              ),
            ),
          if (vm.phase == ScanPhase.failure && vm.error != null)
            Positioned.fill(
              child: ScanSheetFrame(
                child: ScanFailureContent(error: vm.error!, onRetry: vm.retry, onScanAgain: vm.reset),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.icon, required this.onTap});

  final String label, icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: p.paper.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(icon, size: 20, color: p.paper),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.buttonM.copyWith(color: p.paper),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

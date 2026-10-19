import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../utils/geo.dart';

/// Kamera önizlemesi. İzin reddi / kamera yok / web'de destek yoksa tasarımdaki
/// bulanık zemin + açıklama gösterilir (ekran yine de "Galeriden" ve demo ile kullanılabilir).
class ScanCamera extends StatelessWidget {
  const ScanCamera({super.key, required this.controller, required this.onDetect});

  final MobileScannerController controller;
  final ValueChanged<String?> onDetect;

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: controller,
    onDetect: (capture) => onDetect(capture.barcodes.firstOrNull?.rawValue),
    placeholderBuilder: (_) => const ScanBackdrop(),
    errorBuilder: (context, error) => ScanBackdrop(
      message: switch (error.errorCode) {
        MobileScannerErrorCode.permissionDenied => context.l10n.cardCameraDenied,
        MobileScannerErrorCode.unsupported => context.l10n.cardCameraUnsupported,
        _ => context.l10n.cardCameraError,
      },
      showSettings: error.errorCode == MobileScannerErrorCode.permissionDenied,
    ),
  );
}

/// Tasarımdaki bulanık mekân zemini (kamera görüntüsü yokken).
class ScanBackdrop extends StatelessWidget {
  const ScanBackdrop({super.key, this.message, this.showSettings = false});

  final String? message;
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.night),
        Opacity(
          opacity: .55,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: SvgArt(
              '<svg viewBox="0 0 393 852" preserveAspectRatio="xMidYMid slice">'
              '<rect x="40" y="180" width="160" height="300" rx="10" fill="${p.buanShadow.hex}"/>'
              '<rect x="210" y="240" width="150" height="360" rx="10" fill="${p.mapWater.hex}"/>'
              '<circle cx="120" cy="620" r="90" fill="${p.ctaShadow.hex}"/>'
              '<rect x="0" y="700" width="393" height="152" fill="${p.night.hex}"/></svg>',
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (message != null)
          Positioned(
            left: 32,
            right: 32,
            top: MediaQuery.paddingOf(context).top + 76,
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: p.paper.withValues(alpha: .14), borderRadius: BorderRadius.circular(AppRadii.md)),
                child: Column(
                  children: [
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(14, weight: FontWeight.w800, color: p.onNight),
                    ),
                    if (showSettings) ...[
                      const SizedBox(height: 8),
                      AppButton(label: context.l10n.cardOpenSettings, size: AppButtonSize.small, expand: false, onPressed: openAppSettings),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

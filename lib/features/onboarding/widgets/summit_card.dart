import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import 'motion.dart';

/// Dijital Gençlik Kartı (300×190): ön yüz mor gradyan + holografik parlama,
/// arka yüz QR + check-in kodu. [flip] 0 → ön, 1 → arka (rotateY 180°).
class SummitCard extends StatelessWidget {
  const SummitCard({
    super.key,
    required this.flip,
    required this.name,
    required this.memberNo,
    required this.level,
    required this.qrData,
    required this.checkInCode,
    this.tilt = 0,
  });

  final double flip, tilt;
  final String name, memberNo, level, qrData, checkInCode;

  @override
  Widget build(BuildContext context) {
    final angle = flip * math.pi;
    final back = angle > math.pi / 2;
    return Semantics(
      image: true,
      label: context.l10n.onbSummitCardSemantics(name, memberNo, level),
      excludeSemantics: true,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 1 / 1100)
          ..rotateY(angle),
        child: SizedBox(
          width: 300,
          height: 190,
          child: back
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: _Back(qrData: qrData, code: checkInCode),
                )
              : _Front(name: name, memberNo: memberNo, level: level, tilt: tilt),
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.name, required this.memberNo, required this.level, required this.tilt});

  final String name, memberNo, level;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: p.buanGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.onBuan.withValues(alpha: .15)),
        boxShadow: [BoxShadow(color: p.buanShadow.withValues(alpha: .67), blurRadius: 70, offset: const Offset(0, 30))],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: LoopMotion(
              duration: const Duration(seconds: 4),
              reverse: false,
              builder: (_, t, _) {
                final a = (110 + tilt * 40) * math.pi / 180;
                final dir = Alignment(math.cos(a), math.sin(a));
                final shift = (t * 2 - 1) * 1.5;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-dir.x + shift, -dir.y),
                      end: Alignment(dir.x + shift, dir.y),
                      colors: [
                        p.onBuan.withValues(alpha: 0),
                        p.glow.withValues(alpha: .33),
                        p.hotFill.withValues(alpha: .27),
                        p.secondary.withValues(alpha: .33),
                        p.onBuan.withValues(alpha: 0),
                      ],
                      stops: const [.2, .38, .48, .58, .76],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(l.brandCity, maxLines: 1, style: AppTypography.script(19, color: p.onBuan)),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l.brandClub,
                              maxLines: 1,
                              style: AppTypography.display(17, height: .9, color: p.onBuan).copyWith(letterSpacing: .6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (level.isNotEmpty)
                      Transform.rotate(
                        angle: 5 * math.pi / 180,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.tile5,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: p.onTile, width: 2),
                          ),
                          child: Text(
                            level,
                            style: AppTypography.body(12, weight: FontWeight.w900, color: p.onTile),
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(26, height: 1, color: p.onBuan),
                    ),
                    const SizedBox(height: 2),
                    if (memberNo.isNotEmpty)
                      Opacity(
                        opacity: .9,
                        child: Text(
                          l.onbSummitMemberNo(memberNo),
                          style: AppTypography.number(12, color: p.onBuan).copyWith(letterSpacing: 1.5),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.qrData, required this.code});

  final String qrData, code;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: p.night.withValues(alpha: .5), blurRadius: 70, offset: const Offset(0, 30))],
      ),
      child: Row(
        children: [
          if (qrData.isNotEmpty)
            QrImageView(
              data: qrData,
              size: 150,
              padding: EdgeInsets.zero,
              backgroundColor: p.paper,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: p.onTile),
              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: p.onTile),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.onbSummitCheckIn,
                  style: AppTypography.body(12, weight: FontWeight.w900, color: p.onTile),
                ),
                const SizedBox(height: 6),
                Text(code, style: AppTypography.display(30, color: p.onTile).copyWith(letterSpacing: 2)),
                const SizedBox(height: 6),
                Text(
                  l.onbSummitRefresh,
                  style: AppTypography.body(11, weight: FontWeight.w800, color: p.onTile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

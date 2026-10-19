import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../permission_gateway.dart';
import 'motion.dart';

/// A8 · Tek izin kartı (r34): üstte 280 px renkli sahne + süzülen 3B obje,
/// altta başlık, açıklama ve "Şimdi değil / İzin Ver".
class PermissionCard extends StatelessWidget {
  const PermissionCard({super.key, required this.kind, required this.onAllow, required this.onSkip, this.interactive = true});

  final OnbPermission kind;
  final VoidCallback onAllow, onSkip;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final (chip, title, body, bg) = switch (kind) {
      OnbPermission.location => (l.onbPermLocationChip, l.onbPermLocationTitle, l.onbPermLocationBody, p.tile3),
      OnbPermission.notifications => (l.onbPermNotifChip, l.onbPermNotifTitle, l.onbPermNotifBody, p.tile6),
      OnbPermission.motion => (l.onbPermStepsChip, l.onbPermStepsTitle, l.onbPermStepsBody, p.tile5),
    };
    return Semantics(
      container: true,
      label: title,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.sf,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [BoxShadow(color: p.night.withValues(alpha: .28), blurRadius: 50, offset: const Offset(0, 24))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 50,
              child: ColoredBox(
                color: bg,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: -60,
                      top: -60,
                      child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: p.paper.withValues(alpha: .35))),
                    ),
                    Positioned(
                      bottom: 40,
                      child: Container(
                        width: 120,
                        height: 18,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(60), color: p.night.withValues(alpha: .16)),
                      ),
                    ),
                    LoopMotion(
                      duration: const Duration(milliseconds: 1500),
                      builder: (_, t, child) {
                        final e = Curves.easeInOut.transform(t);
                        return Transform.translate(
                          offset: Offset(0, -10 * e),
                          child: Transform.rotate(angle: (-4 + 8 * e) * math.pi / 180, child: child),
                        );
                      },
                      child: ExcludeSemantics(child: _Art(kind: kind)),
                    ),
                    Positioned(
                      left: 18,
                      top: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: p.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.onTile, width: 2),
                        ),
                        child: Text(chip, style: AppTypography.body(14, weight: FontWeight.w900, color: p.onTile)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 50,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(title, style: AppTypography.display(28, height: 1.05, color: p.ink))),
                    const SizedBox(height: 10),
                    Flexible(
                      child: Text(body, overflow: TextOverflow.fade, style: AppTypography.body(15, height: 1.45, color: p.mut)),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          flex: 10,
                          child: OutlinedButton(
                            onPressed: interactive ? onSkip : null,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: const StadiumBorder(),
                              side: BorderSide(color: p.borderStrong, width: 2),
                              foregroundColor: p.ink,
                            ),
                            child: Text(l.onbPermNotNow, maxLines: 1, style: AppTypography.buttonM.copyWith(color: p.ink)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 13,
                          child: AppButton(label: l.onbPermAllow, size: AppButtonSize.medium, onPressed: interactive ? onAllow : null),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.kind});

  final OnbPermission kind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return switch (kind) {
      OnbPermission.location => Transform.rotate(
          angle: -math.pi / 4,
          child: Container(
            width: 124,
            height: 124,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(62),
                topRight: Radius.circular(62),
                bottomRight: Radius.circular(62),
                bottomLeft: Radius.circular(10),
              ),
              gradient: RadialGradient(
                center: const Alignment(-.4, -.4),
                radius: .9,
                colors: [Color.lerp(p.primary, p.paper, .6)!, p.primary, Color.lerp(p.primary, p.night, .25)!],
                stops: const [0, .45, 1],
              ),
              boxShadow: [BoxShadow(color: p.night.withValues(alpha: .2), blurRadius: 30, offset: const Offset(0, 20))],
            ),
            child: Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: p.paper)),
          ),
        ),
      OnbPermission.notifications => SvgArt(
          '<svg viewBox="0 0 120 120"><defs><radialGradient id="b" cx=".32" cy=".28" r=".8">'
          '<stop offset="0" stop-color="${p.paper.hex}" stop-opacity=".75"/><stop offset=".35" stop-color="${p.cta.hex}"/>'
          '<stop offset="1" stop-color="${p.ctaShadow.hex}"/></radialGradient></defs>'
          '<path d="M60 14c-20 0-34 16-34 36v22l-10 14h88l-10-14V50c0-20-14-36-34-36z" fill="url(#b)"/>'
          '<circle cx="60" cy="98" r="11" fill="${p.hotFill.hex}"/><circle cx="92" cy="26" r="13" fill="${p.hotFill.hex}"/>'
          '<path d="M87 20h8l-4.5 5c2.5 0 4.5 1.6 4.5 4s-2 4-4.5 4c-1.6 0-3-.7-3.8-1.8" stroke="${p.onHot.hex}" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>',
          width: 150,
          height: 150,
        ),
      OnbPermission.motion => SvgArt(
          '<svg viewBox="0 0 140 100"><defs><linearGradient id="s" x1="0" y1="0" x2="0" y2="1">'
          '<stop offset="0" stop-color="${p.secondary.hex}"/><stop offset="1" stop-color="${p.grnT.hex}"/></linearGradient></defs>'
          '<path d="M14 52c0-14 6-30 16-30 8 0 10 10 22 14 12 4 24 4 36 10 14 6 34 10 40 22 4 8-2 14-12 14H22C14 82 14 70 14 52z" fill="url(#s)"/>'
          '<path d="M12 76h120v8a6 6 0 0 1-6 6H18a6 6 0 0 1-6-6z" fill="${p.paper.hex}"/>'
          '<path d="M46 40l10 8M58 42l10 8M70 46l8 8" stroke="${p.paper.hex}" stroke-width="4" stroke-linecap="round"/>'
          '<ellipse cx="34" cy="40" rx="10" ry="6" fill="${p.paper.hex}" fill-opacity=".4"/></svg>',
          width: 170,
          height: 130,
        ),
    };
  }
}

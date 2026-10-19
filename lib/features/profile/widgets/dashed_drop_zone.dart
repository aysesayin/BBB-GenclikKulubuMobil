import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import 'profile_icons.dart';

/// 120 px kesik çizgili yükleme alanı: ikon + başlık + açıklama.
class DashedDropZone extends StatelessWidget {
  const DashedDropZone({super.key, required this.title, required this.hint, required this.onTap});

  final String title, hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: title,
      hint: hint,
      excludeSemantics: true,
      child: Material(
        color: p.bg,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          child: CustomPaint(
            painter: _DashedBorder(color: p.line),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(ProfileIcons.upload, size: 30, color: p.teal),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(12, color: p.mut),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadii.tile)).deflate(1);
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, (d + 6).clamp(0, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// Seçilmiş dosya satırı: dosya ikonu + ad + kaldır butonu.
class PickedFileRow extends StatelessWidget {
  const PickedFileRow({super.key, required this.name, required this.removeLabel, required this.onRemove, this.icon = ProfileIcons.file});

  final String name, removeLabel, icon;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
      decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          AppIcon(icon, size: 22, color: p.mut),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink),
            ),
          ),
          AppIconButton(icon: AppIcons.close, semanticLabel: removeLabel, color: p.mut, iconSize: 18, onPressed: onRemove),
        ],
      ),
    );
  }
}

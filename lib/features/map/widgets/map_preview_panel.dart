import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/map/map_pin.dart';
import '../../../l10n/l10n.dart';
import '../../events/widgets/discover_palette.dart';
import 'map_icons.dart';

/// G3 pin önizleme paneli (alt navigasyonun hemen üstünde): 64 px karo + ad/alt satır/durum,
/// "Detay" ve "Yol tarifi al". Aşağı sürükleyince kapanır.
class MapPreviewPanel extends StatelessWidget {
  const MapPreviewPanel({super.key, required this.pin, required this.onDetail, required this.onDirections, required this.onClose});

  final MapPin pin;
  final VoidCallback? onDetail;
  final VoidCallback onDirections;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 200) onClose();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: p.sf,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
          boxShadow: [BoxShadow(color: p.shadowColor, blurRadius: 24, offset: const Offset(0, -8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3))),
            ),
            const SizedBox(height: 10),
            Semantics(
              container: true,
              liveRegion: true,
              child: Row(
                children: [
                  IconTile(icon: MapIcons.forKey(pin.icon), color: paletteColor(p, pin.tone), size: 64, radius: 18, iconSize: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pin.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.body(16, weight: FontWeight.w900, color: p.ink)),
                        const SizedBox(height: 2),
                        if (pin.subtitle.isNotEmpty)
                          Text(pin.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body(13, color: p.mut)),
                        if (pin.status.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            pin.status,
                            style: AppTypography.body(12, weight: FontWeight.w900, color: pin.statusTone == 'warn' ? p.pinkT : p.grnT),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppButton(label: l.mapDetail, onPressed: onDetail, variant: AppButtonVariant.outlineInk, size: AppButtonSize.medium),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(label: l.mapDirections, icon: MapIcons.navigate, onPressed: onDirections, size: AppButtonSize.medium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/photo_report.dart';
import '../../../../../l10n/l10n.dart';
import '../../widgets/task_icons.dart';
import '../view_model/photo_report_view_model.dart';

/// 220 px fotoğraf alanı: seçilmediyse illüstrasyon + yönerge, seçildiyse önizleme.
/// Altta konum çipi, sağda kamera / galeri butonları.
class PhotoStage extends StatelessWidget {
  const PhotoStage({
    super.key,
    required this.photo,
    required this.issue,
    required this.location,
    required this.onCamera,
    required this.onGallery,
    required this.onLocation,
  });

  final Uint8List? photo;
  final bool issue;
  final LocationStatus location;
  final VoidCallback onCamera, onGallery, onLocation;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final glass = p.paper.withValues(alpha: .92);
    final (String locText, VoidCallback? locTap) = switch (location) {
      LocationStatus.added => (l.taskPhotoLocationAdded, null),
      LocationStatus.loading => (l.taskPhotoLocationLoading, null),
      LocationStatus.denied => (l.taskPhotoLocationDenied, onLocation),
      LocationStatus.none => (l.taskPhotoLocationAdd, onLocation),
    };
    Widget round(String icon, String label, VoidCallback onTap) =>
        AppIconButton(icon: icon, semanticLabel: label, onPressed: onTap, background: glass, color: p.onTile, iconSize: 20);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              Image.memory(photo!, fit: BoxFit.cover, gaplessPlayback: true)
            else ...[
              ColoredBox(color: issue ? p.tile3 : p.tile2),
              SvgArt(
                '<svg viewBox="0 0 353 220"><rect x="0" y="150" width="353" height="70" fill="${p.secondary.hex}" opacity=".7"/>'
                '<rect x="150" y="40" width="44" height="130" rx="4" fill="${p.buanFill.hex}" opacity=".8"/>'
                '<path d="M146 44 L172 14 L198 44 Z" fill="${p.buanFill.hex}"/><circle cx="172" cy="70" r="12" fill="${p.paper.hex}"/>'
                '<path d="M172 62v8l5 3" stroke="${p.onTile.hex}" stroke-width="2" fill="none"/><circle cx="290" cy="50" r="22" fill="${p.cta.hex}"/>'
                '<path d="M30 150 q20-40 40 0M60 150 q20-50 40 0" fill="${p.grnT.hex}" opacity=".6"/></svg>',
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Center(
                  child: TagBadge(label: l.taskPhotoEmptyPrompt, background: glass, foreground: p.onTile),
                ),
              ),
            ],
            Positioned(
              left: 12,
              bottom: 12,
              child: Semantics(
                button: locTap != null,
                child: GestureDetector(
                  onTap: locTap,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: glass, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(AppIcons.pinSimple, size: 14, color: p.onTile, strokeWidth: 2.6),
                        const SizedBox(width: 6),
                        Text(
                          locText,
                          style: AppTypography.body(12, weight: FontWeight.w900, color: p.onTile),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  round(TaskIcons.cameraAlt, photo == null ? l.taskPhotoCamera : l.taskPhotoRetakeCamera, onCamera),
                  const SizedBox(width: 8),
                  round(TaskIcons.gallery, l.taskPhotoGallery, onGallery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Gönderilerim" satırı: küçük görsel, başlık, tarih · tür · not, moderasyon durumu.
class PhotoReportRow extends StatelessWidget {
  const PhotoReportRow({super.key, required this.report, required this.tile});

  final PhotoReport report;
  final Color tile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final (String label, Color bg, Color fg, String icon) = switch (report.status) {
      ReportStatus.approved => (l.taskPhotoStatusApproved(Fmt.signed(report.reward)), p.grnS, p.grnT, AppIcons.check),
      ReportStatus.pending => (l.taskPhotoStatusPending, p.yelS, p.warningText, AppIcons.clock),
      ReportStatus.rejected => (l.taskPhotoStatusRejected, p.pinkS, p.pinkT, AppIcons.close),
    };
    final note = report.statusNote ?? '';
    final sub = [
      DateFormat('d MMM', locale).format(report.createdAt.toLocal()),
      if (report.typeLabel.isNotEmpty) report.typeLabel,
      if (note.isNotEmpty) note,
    ].join(' · ');
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox.square(
              dimension: 44,
              child: report.thumbnailUrl == null
                  ? ColoredBox(color: tile)
                  : CachedNetworkImage(
                      imageUrl: report.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => ColoredBox(color: tile),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(12, color: p.mut),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(icon, size: 12, color: fg, strokeWidth: 3),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.body(12, weight: FontWeight.w900, color: fg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

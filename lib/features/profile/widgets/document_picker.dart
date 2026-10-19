import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../view_model/picked_document.dart';

/// Kamera / galeri seçimi sunar ve seçilen görseli [PickedDocument] olarak döndürür.
// TODO(varsayım): Tasarım PDF de diyor; image_picker yalnız görsel seçer. PDF için file_picker paketi
// eklenmeli (pubspec entegratörde). Şimdilik JPG/PNG.
Future<PickedDocument?> pickDocument(BuildContext context) async {
  final l = context.l10n;
  final source = await AppSheet.show<ImageSource>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SourceRow(icon: AppIcons.camera, label: l.profileDiscountPickCamera, onTap: () => Navigator.of(ctx).pop(ImageSource.camera)),
        const SizedBox(height: 8),
        _SourceRow(icon: AppIcons.grid, label: l.profileDiscountPickGallery, onTap: () => Navigator.of(ctx).pop(ImageSource.gallery)),
      ],
    ),
  );
  if (source == null) return null;
  final file = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 2400);
  if (file == null) return null;
  return PickedDocument(path: file.path, name: file.name, sizeBytes: await file.length());
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.icon, required this.label, required this.onTap});

  final String icon, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      color: p.bg,
      radius: AppRadii.md,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppIcon(icon, size: 22, color: p.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
            ),
          ),
        ],
      ),
    );
  }
}

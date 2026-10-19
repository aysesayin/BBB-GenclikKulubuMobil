import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/places/place.dart';
import '../../../l10n/l10n.dart';
import '../../events/widgets/discover_palette.dart';

/// G4 galeri (280 px): kaydırılabilir görseller + nokta göstergesi.
/// Görsel adresi yoksa tasarımdaki bina çizimi tonuna göre gösterilir.
class PlaceGallery extends StatefulWidget {
  const PlaceGallery({super.key, required this.images, required this.index, required this.onChanged, this.height = 280});

  final List<PlaceGalleryImage> images;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  State<PlaceGallery> createState() => _PlaceGalleryState();
}

class _PlaceGalleryState extends State<PlaceGallery> {
  late final _controller = PageController(initialPage: widget.index);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int i) {
    Haptics.selection();
    if (context.reduceMotion) {
      _controller.jumpToPage(i);
    } else {
      _controller.animateToPage(i, duration: AppDurations.sheet, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final images = widget.images.isEmpty ? const [PlaceGalleryImage()] : widget.images;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Semantics(
            label: l.placeGallerySemantics(widget.index + 1, images.length),
            child: PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: widget.onChanged,
              itemBuilder: (_, i) => _GalleryImage(image: images[i]),
            ),
          ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < images.length; i++)
                    Semantics(
                      button: true,
                      selected: i == widget.index,
                      label: l.placeGalleryImage(i + 1),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _go(i),
                        child: SizedBox(
                          width: 28 + 6,
                          height: 44,
                          child: Center(
                            child: AnimatedContainer(
                              duration: AppDurations.fast,
                              width: i == widget.index ? 22 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: p.paper.withValues(alpha: i == widget.index ? 1 : .6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.image});

  final PlaceGalleryImage image;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, body, roof) = galleryTones(p, image.tone);
    final cols = [90, 130, 170, 210, 250, 290]
        .map((x) => '<rect x="$x" y="110" width="16" height="170" fill="${p.paper.hex}" fill-opacity=".75"/>')
        .join();
    final svg = '<svg viewBox="0 0 393 280" preserveAspectRatio="xMidYMax slice">'
        '<rect x="70" y="80" width="250" height="200" fill="${body.hex}"/>'
        '<path d="M60 84 L195 30 L330 84 Z" fill="${roof.hex}"/>$cols'
        '<rect x="170" y="190" width="50" height="90" rx="25" fill="${p.onTile.hex}" fill-opacity=".6"/></svg>';
    final art = ColoredBox(color: bg, child: SvgArt(svg, fit: BoxFit.cover));
    final url = image.url;
    if (url == null) return art;
    return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (_, _) => art, errorWidget: (_, _, _) => art);
  }
}

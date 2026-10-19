import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/stories/story.dart';
import '../../../l10n/l10n.dart';
import '../../home/widgets/home_icons.dart';

/// Segment teması → (zemin, blob1, dağ2, dağ3, etiket zemini).
(Color, Color, Color, Color, Color) storyTheme(AppPalette p, String theme) => switch (theme) {
  'buan' => (p.buanFill, p.hotFill, p.night, p.coinMark, p.tile1),
  'fresh' => (p.tealB, p.sky, p.teal, p.secondary, p.tile6),
  _ => (p.teal, p.primary, p.grnT, p.secondary, p.tile2),
};

/// Tam ekran illüstrasyon + okunabilirlik karartması.
class StoryBackdrop extends StatelessWidget {
  const StoryBackdrop({super.key, required this.slide});

  final StorySlide slide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, b1, b2, b3, _) = storyTheme(p, slide.theme);
    final art =
        '<svg viewBox="0 0 393 852" preserveAspectRatio="xMidYMid slice">'
        '<path d="M260 60c110 0 170 90 150 200s-120 160-220 140S40 280 70 180 160 60 260 60z" fill="${b1.hex}"/>'
        '<path d="M-40 560 L90 380 L180 500 L260 400 L440 600 L440 852 L-40 852 Z" fill="${b2.hex}"/>'
        '<path d="M-40 640 L120 520 L240 620 L330 560 L440 660 L440 852 L-40 852 Z" fill="${b3.hex}"/>'
        '<path d="M170 600 L210 530 L250 600 Z" fill="${p.cta.hex}"/>'
        '<circle cx="300" cy="230" r="44" fill="${p.cta.hex}" fill-opacity=".9"/></svg>';
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: bg),
        LayoutBuilder(
          builder: (_, c) => SvgArt(art, fit: BoxFit.cover, width: c.maxWidth, height: c.maxHeight),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .22, .5, 1],
              colors: [
                p.night.withValues(alpha: .55),
                p.night.withValues(alpha: 0),
                p.night.withValues(alpha: 0),
                p.night.withValues(alpha: .85),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Üstteki ilerleme segmentleri. [progress] yalnız etkin segmenti doldurur.
class StorySegments extends StatelessWidget {
  const StorySegments({super.key, required this.count, required this.index, required this.progress});

  final int count, index;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: context.l10n.storyProgress(index + 1, count),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var k = 0; k < count; k++) ...[
              if (k > 0) const SizedBox(width: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: ColoredBox(
                      color: p.paper.withValues(alpha: .35),
                      child: AnimatedBuilder(
                        animation: progress,
                        builder: (_, _) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: k < index ? 1 : (k == index ? progress.value : 0),
                          child: ColoredBox(color: p.paper),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Alt bilgi bloğu: sticker etiket + başlık + açıklama + CTA.
class StoryCaption extends StatelessWidget {
  const StoryCaption({super.key, required this.slide, required this.onCta});

  final StorySlide slide;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (_, _, _, _, tagBg) = storyTheme(p, slide.theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (slide.tag.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.rotate(
              angle: -3 * 3.1415926535 / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.onTile, width: 2),
                  boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(3, 3))],
                ),
                child: Text(
                  slide.tag,
                  style: AppTypography.body(13, weight: FontWeight.w900, color: p.onTile),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(slide.title, style: AppTypography.display(36, color: p.paper, height: 1.02)),
        ),
        if (slide.body.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: AppTypography.body(16, weight: FontWeight.w600, color: p.paper.withValues(alpha: .92), height: 1.45),
          ),
        ],
        if (slide.ctaLabel case final cta? when onCta != null) ...[
          const SizedBox(height: 18),
          Semantics(
            button: true,
            label: cta,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onCta,
              child: Container(
                height: 56,
                decoration: BoxDecoration(color: p.cta, borderRadius: BorderRadius.circular(28)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        cta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.buttonL.copyWith(color: p.onCta),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppIcon(HomeIcons.arrowRight, size: 20, color: p.onCta, strokeWidth: 2.6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_items.dart';
import '../../../l10n/l10n.dart';
import '../home_links.dart';

/// Banner karuseli: oran 1.75 (yükseklik = (genişlik − 40) / 1.75), noktalar,
/// otomatik ilerleme ("Hareketi azalt" açıkken kapalı).
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, required this.banners});

  final List<HomeBanner> banners;

  // TODO(varsayım): Otomatik geçiş aralığı tasarımda yok; 5 sn seçildi.
  static const interval = Duration(seconds: 5);

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (context.reduceMotion || widget.banners.length < 2) return;
    _timer = Timer.periodic(HomeBannerCarousel.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final n = widget.banners.length;
    return Semantics(
      container: true,
      label: l.homeHighlightsSemantics,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: LayoutBuilder(
          builder: (context, c) => Column(
            children: [
              SizedBox(
                height: (c.maxWidth / 1.75).roundToDouble(),
                child: NotificationListener<ScrollStartNotification>(
                  onNotification: (_) {
                    _restartTimer();
                    return false;
                  },
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: n,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => _BannerCard(banner: widget.banners[i], position: l.homeBannerPosition(i + 1, n)),
                  ),
                ),
              ),
              if (n > 1)
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < n; i++)
                          AnimatedContainer(
                            duration: context.reduceMotion ? Duration.zero : AppDurations.fast,
                            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                            width: i == _index ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(color: i == _index ? p.teal : p.line, borderRadius: BorderRadius.circular(3)),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.position});

  final HomeBanner banner;
  final String position;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, b1, b2, fg) = switch (banner.theme) {
      'teal' => (p.isDark ? p.tealS : p.teal, p.tealB, p.cta, p.paper),
      'green' => (p.isDark ? p.grnS : p.grnT, p.coinMark, p.cta, p.paper),
      'night' => (p.night, p.buanFill, p.cta, p.onNight),
      _ => (p.buanFill, p.coinMark, p.cta, p.onBuan),
    };
    final w = p.paper.hex;
    final art =
        '<svg viewBox="0 0 353 202" preserveAspectRatio="xMidYMid slice">'
        '<path d="M220 -20c70 0 150 40 150 120s-60 130-140 120-100-60-90-130 10-110 80-110z" fill="${b1.hex}"/>'
        '<path d="M290 120c30 0 60 20 55 50s-30 50-60 45-45-30-40-55 15-40 45-40z" fill="${b2.hex}"/>'
        '<circle cx="250" cy="70" r="38" fill="$w" fill-opacity=".18"/>'
        '<path d="M200 150 L250 60 L300 150 Z" fill="${p.secondary.hex}" fill-opacity=".9"/>'
        '<path d="M236 86 L250 60 L264 86 Z" fill="$w"/>'
        '<path d="M150 40 L340 20" stroke="$w" stroke-width="2" stroke-opacity=".7"/>'
        '<rect x="268" y="18" width="20" height="16" rx="4" fill="$w"/></svg>';
    return Semantics(
      button: true,
      label: '${banner.title}, $position',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => openLink(context, banner.link),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: ColoredBox(
            color: bg,
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  Positioned.fill(
                    child: SvgArt(art, fit: BoxFit.cover, width: c.maxWidth, height: c.maxHeight),
                  ),
                  Positioned(
                    left: 18,
                    top: 18,
                    bottom: 18,
                    width: c.maxWidth * .58,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (banner.kicker.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: p.paper.withValues(alpha: .18), borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              trUpper(banner.kicker),
                              maxLines: 1,
                              style: AppTypography.body(11, weight: FontWeight.w800, color: fg).copyWith(letterSpacing: .4),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            banner.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.display(22, color: fg),
                          ),
                        ),
                        if (banner.ctaLabel case final cta?)
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: p.cta, borderRadius: BorderRadius.circular(17)),
                            child: Text(
                              cta,
                              maxLines: 1,
                              style: AppTypography.body(13, weight: FontWeight.w900, color: p.onCta),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

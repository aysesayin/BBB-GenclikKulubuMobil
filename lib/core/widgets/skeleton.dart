import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Shimmer kaynağı: alt ağaçtaki tüm [SkeletonBox]'lar aynı faza göre parlar (1200 ms).
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  static Animation<double>? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppDurations.shimmer);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.commonLoading,
        liveRegion: true,
        child: ExcludeSemantics(child: _ShimmerScope(animation: _c, child: widget.child)),
      );
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});
  final Animation<double> animation;
  @override
  bool updateShouldNotify(_ShimmerScope old) => old.animation != animation;
}

/// Gri yer tutucu kutu. [Shimmer] içindeyse parlar.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 8, this.circle = false});

  final double? width;
  final double height, radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final anim = Shimmer.of(context);
    BoxDecoration deco(double t) => BoxDecoration(
          borderRadius: circle ? null : BorderRadius.circular(radius),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          gradient: LinearGradient(
            begin: Alignment(-3 + 4 * t, 0),
            end: Alignment(-1 + 4 * t, 0),
            colors: [p.sf2, p.line, p.sf2],
          ),
        );
    if (anim == null) return Container(width: width, height: height, decoration: deco(.5));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) => Container(width: width, height: height, decoration: deco(anim.value)),
    );
  }
}

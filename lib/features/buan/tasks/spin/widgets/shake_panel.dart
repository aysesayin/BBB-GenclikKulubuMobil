import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../l10n/l10n.dart';

/// "Salla Kazan": ivmeölçerle sallama algılanınca [onShake]. Sensör yoksa
/// (web, masaüstü) buton her zaman alternatif yoldur.
class ShakePanel extends StatefulWidget {
  const ShakePanel({super.key, required this.onShake, required this.enabled});

  final VoidCallback onShake;
  final bool enabled;

  @override
  State<ShakePanel> createState() => _ShakePanelState();
}

class _ShakePanelState extends State<ShakePanel> with SingleTickerProviderStateMixin {
  // TODO(varsayım): Eşik 14 m/s², 800 ms içinde 2 tepe — cihaz testinde ayarlanacak.
  static const _threshold = 14.0;
  static const _window = Duration(milliseconds: 800);

  late final AnimationController _wiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  StreamSubscription<UserAccelerometerEvent>? _sub;
  DateTime? _firstPeak;

  @override
  void initState() {
    super.initState();
    try {
      _sub = userAccelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(_onEvent, onError: (Object _) {}, cancelOnError: true);
    } on Object {
      _sub = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _wiggle.stop();
    } else {
      _wiggle.repeat(reverse: true);
    }
  }

  void _onEvent(UserAccelerometerEvent e) {
    if (!widget.enabled) return;
    final g = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (g < _threshold) return;
    final now = DateTime.now();
    final first = _firstPeak;
    if (first == null || now.difference(first) > _window) {
      _firstPeak = now;
      return;
    }
    _firstPeak = null;
    Haptics.medium();
    widget.onShake();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final phone = SvgArt(
      '<svg viewBox="0 0 150 220"><rect x="20" y="10" width="110" height="200" rx="22" fill="${p.onTile.hex}" stroke="${p.glow.hex}" stroke-width="4"/>'
      '<rect x="32" y="30" width="86" height="150" rx="10" fill="${p.coinMark.hex}"/><path d="M62 85l30 20-30 20z" fill="${p.paper.hex}"/>'
      '<path d="M6 60 Q-4 110 6 160M144 60 Q154 110 144 160" stroke="${p.cta.hex}" stroke-width="5" fill="none" stroke-linecap="round"/></svg>',
      width: 150,
      height: 220,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _wiggle,
            child: phone,
            builder: (_, child) => Transform.rotate(angle: (_wiggle.value * 2 - 1) * 8 * math.pi / 180, child: child),
          ),
          const SizedBox(height: 22),
          Semantics(
            header: true,
            child: Text(
              l.taskSpinShakeTitle,
              textAlign: TextAlign.center,
              style: AppTypography.display(28, color: p.onNight),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l.taskSpinShakeHint,
            textAlign: TextAlign.center,
            style: AppTypography.body(15, color: p.onNight.withValues(alpha: .9)),
          ),
          const SizedBox(height: 22),
          AppButton(label: l.taskSpinShakeCta, onPressed: widget.enabled ? widget.onShake : null),
        ],
      ),
    );
  }
}

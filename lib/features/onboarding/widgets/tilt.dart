import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/utils/haptics.dart';

/// Cihaz eğimi (sensors_plus ivmeölçer) → −1…1 aralığında yumuşatılmış ofset.
/// Paralaks ve holografik parlama için. Hareketi azalt açıkken / sensör yoksa
/// her zaman [Offset.zero].
class TiltBuilder extends StatefulWidget {
  const TiltBuilder({super.key, required this.builder, this.child});

  final Widget Function(BuildContext context, Offset tilt, Widget? child) builder;
  final Widget? child;

  @override
  State<TiltBuilder> createState() => _TiltBuilderState();
}

class _TiltBuilderState extends State<TiltBuilder> {
  StreamSubscription<AccelerometerEvent>? _sub;
  Offset _tilt = Offset.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _sub?.cancel();
      _sub = null;
      _tilt = Offset.zero;
    } else {
      _sub ??= _listen();
    }
  }

  StreamSubscription<AccelerometerEvent>? _listen() {
    try {
      return accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
        (e) {
          final target = Offset((-e.x / 6).clamp(-1.0, 1.0), ((e.y - 6) / 6).clamp(-1.0, 1.0));
          final next = Offset.lerp(_tilt, target, .15)!;
          if (mounted && (next - _tilt).distance > .01) setState(() => _tilt = next);
        },
        onError: (Object _) {},
        cancelOnError: true,
      );
    } on Object {
      return null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _tilt, widget.child);
}

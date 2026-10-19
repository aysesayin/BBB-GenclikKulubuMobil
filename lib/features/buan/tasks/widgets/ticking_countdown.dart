import 'dart:async';

import 'package:flutter/widgets.dart';

/// Saniyede bir yeniden çizen geri sayım (sa:dk:sn). [deadline] sunucu saatidir;
/// arka plandan dönünce de doğru kalan süreyi gösterir.
class TickingCountdown extends StatefulWidget {
  const TickingCountdown({super.key, required this.deadline, required this.builder, this.onFinished});

  final DateTime deadline;
  final Widget Function(BuildContext context, String hms) builder;
  final VoidCallback? onFinished;

  /// 8 sa 12 dk 4 sn → "08:12:04".
  static String hms(Duration d) {
    final s = d.isNegative ? 0 : d.inSeconds;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two(s % 3600 ~/ 60)}:${two(s % 60)}';
  }

  @override
  State<TickingCountdown> createState() => _TickingCountdownState();
}

class _TickingCountdownState extends State<TickingCountdown> {
  Timer? _t;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_fired && !widget.deadline.isAfter(DateTime.now())) {
        _fired = true;
        widget.onFinished?.call();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, TickingCountdown.hms(widget.deadline.difference(DateTime.now())));
}

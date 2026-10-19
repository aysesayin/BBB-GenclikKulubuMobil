import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/l10n.dart';

/// Sezon geri sayımı çipi: "2g 14s 08d" — dakikada bir yenilenir.
class SeasonCountdown extends StatefulWidget {
  const SeasonCountdown({super.key, required this.endsAt, this.now});

  final DateTime endsAt;
  final DateTime Function()? now;

  @override
  State<SeasonCountdown> createState() => _SeasonCountdownState();
}

class _SeasonCountdownState extends State<SeasonCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    var left = widget.endsAt.difference(widget.now?.call() ?? DateTime.now());
    if (left.isNegative) left = Duration.zero;
    final d = left.inDays, h = left.inHours % 24, m = left.inMinutes % 60;
    return Semantics(
      label: l.buanLeagueCountdownSemantics(d, h),
      excludeSemantics: true,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: p.sf2, borderRadius: BorderRadius.circular(17)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.clock, size: 16, color: p.ink, strokeWidth: 2.4),
            const SizedBox(width: 6),
            Text(l.buanLeagueCountdown(d, h, m.toString().padLeft(2, '0')), style: AppTypography.number(13, color: p.ink)),
          ],
        ),
      ),
    );
  }
}

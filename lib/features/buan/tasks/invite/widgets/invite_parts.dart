import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/referral.dart';
import '../../../../../l10n/l10n.dart';

/// Üst kahraman alanı: tile4 zemin, pembe blob, başlık + ödül açıklaması + maskot.
class InviteHero extends StatelessWidget {
  const InviteHero({super.key, required this.inviterReward, required this.inviteeReward});

  final int inviterReward, inviteeReward;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final you = Fmt.signed(inviterReward), friend = Fmt.signed(inviteeReward);
    final body = l.taskInviteHeroBody(you, friend);
    final base = AppTypography.body(14, weight: FontWeight.w800, color: p.onTile);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        color: p.tile4,
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 8, 20, 26),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -80,
              bottom: -66,
              child: SvgArt(
                '<svg viewBox="0 0 240 220"><path d="M130 10c60 0 105 45 100 105s-50 100-110 100S10 165 18 105 70 10 130 10z" fill="${p.tile1.hex}"/></svg>',
                width: 240,
                height: 220,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(-12, 0),
                  child: AppIconButton(
                    icon: AppIcons.back,
                    semanticLabel: l.commonBack,
                    color: p.onTile,
                    iconSize: 24,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(l.taskInviteHeroTitle, style: AppTypography.display(30, height: 1.02, color: p.onTile)),
                          ),
                          const SizedBox(height: 6),
                          Text.rich(TextSpan(children: _bold(body, [you, friend], base)), style: base),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Mascot(mood: MascotMood.celebrate, size: 96),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Metindeki tutarları kalın yapar (çeviri sırası değişse de çalışır).
  static List<TextSpan> _bold(String text, List<String> parts, TextStyle base) {
    final spans = <TextSpan>[];
    var rest = text;
    while (rest.isNotEmpty) {
      var at = -1;
      var hit = '';
      for (final p in parts) {
        final i = rest.indexOf(p);
        if (i >= 0 && (at < 0 || i < at)) (at, hit) = (i, p);
      }
      if (at < 0) {
        spans.add(TextSpan(text: rest));
        break;
      }
      if (at > 0) spans.add(TextSpan(text: rest.substring(0, at)));
      spans.add(
        TextSpan(
          text: hit,
          style: base.copyWith(fontWeight: FontWeight.w900),
        ),
      );
      rest = rest.substring(at + hit.length);
    }
    return spans;
  }
}

/// "Davet ettiklerin" satırı: baş harf avatarı + ad + durum (renk + ikon + metin).
class InviteeRow extends StatelessWidget {
  const InviteeRow({super.key, required this.invitee, required this.avatarColor});

  final Invitee invitee;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final (String label, Color bg, Color fg, String icon) = switch (invitee.status) {
      InviteeStatus.rewarded => (l.taskInviteStatusRewarded(Fmt.signed(invitee.reward)), p.grnS, p.grnT, AppIcons.check),
      InviteeStatus.pending => (l.taskInviteStatusPending, p.yelS, p.warningText, AppIcons.clock),
      InviteeStatus.notRegistered => (l.taskInviteStatusNotRegistered, p.sf2, p.mut, AppIcons.minus),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              invitee.initials,
              style: AppTypography.body(14, weight: FontWeight.w900, color: p.onTile),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              invitee.name,
              style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink),
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

/// Kesikli çerçeveli kod kutusu.
class DashedCodeBox extends StatelessWidget {
  const DashedCodeBox({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: _DashedRRect(p.teal),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SelectableText(code, style: AppTypography.display(28, color: p.ink).copyWith(letterSpacing: 2)),
        ),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  _DashedRRect(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(1), const Radius.circular(16)));
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect o) => o.color != color;
}

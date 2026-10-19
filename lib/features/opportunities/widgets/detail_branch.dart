import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../l10n/l10n.dart';

/// Şube bölümü: başlık, mini harita, ad / mesafe / saatler, "Yol tarifi".
class DetailBranch extends StatelessWidget {
  const DetailBranch({super.key, required this.branch});

  final OpportunityBranch branch;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final sub = [branch.distanceLabel, branch.hours].where((e) => e.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l.oppBranch, style: AppTypography.display(20, color: p.ink)),
        ),
        const SizedBox(height: 10),
        const BranchMiniMap(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink),
                  ),
                  if (sub.isNotEmpty) Text(sub, style: AppTypography.body(13, color: p.mut)),
                ],
              ),
            ),
            if (branch.lat != null && branch.lng != null) ...[
              const SizedBox(width: 12),
              AppButton.outline(
                label: l.oppDirections,
                size: AppButtonSize.small,
                expand: false,
                onPressed: () => launchUrl(
                  Uri.parse(ApiEndpoints.directionsUrlTemplate.replaceAll('{lat}', '${branch.lat}').replaceAll('{lng}', '${branch.lng}')),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Şube mini haritası (dekoratif çizim; gerçek harita Keşfet > Harita'da).
class BranchMiniMap extends StatelessWidget {
  const BranchMiniMap({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.tile),
      child: SizedBox(
        height: 130,
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: p.sky),
              SvgArt(
                '<svg viewBox="0 0 353 130" preserveAspectRatio="xMidYMid slice">'
                '<path d="M-10 90 C80 70 140 110 220 80 S320 50 370 60" stroke="${p.sf.hex}" stroke-width="9" fill="none"/>'
                '<path d="M120 -10 L150 140" stroke="${p.sf.hex}" stroke-width="6"/></svg>',
                fit: BoxFit.cover,
              ),
              Positioned(
                left: c.maxWidth * 160 / 353,
                top: 34,
                child: Transform.rotate(
                  angle: -0.785398,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: p.hotFill,
                      border: Border.all(color: p.paper, width: 3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
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

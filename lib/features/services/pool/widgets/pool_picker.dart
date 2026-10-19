import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/facility.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/svc_format.dart';

/// Yatay havuz kartları (radyo grubu): seçili kart 3 px ink çerçeve + sert gölge.
class PoolPicker extends StatelessWidget {
  const PoolPicker({super.key, required this.pools, required this.selectedId, required this.onSelect});

  final List<Pool> pools;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.svcPoolPickerLabel,
        container: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < pools.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                _PoolCard(pool: pools[i], selected: pools[i].id == selectedId, onTap: () => onSelect(pools[i].id)),
              ],
            ],
          ),
        ),
      );
}

class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.pool, required this.selected, required this.onTap});

  final Pool pool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sub = [pool.district, pool.typeLabel].where((s) => s.isNotEmpty).toList();
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.chip,
          width: 150,
          decoration: BoxDecoration(
            color: p.sf,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: selected ? p.onTile : Colors.transparent, width: 3),
            boxShadow: selected ? [BoxShadow(color: p.onTile, offset: const Offset(4, 4))] : p.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg - 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 72,
                  color: SvcFmt.tile(p, pool.tile),
                  alignment: Alignment.bottomCenter,
                  child: SvgArt(
                    '<svg viewBox="0 0 150 78" preserveAspectRatio="none">'
                    '<path d="M0 50c15 0 15-8 30-8s15 8 30 8 15-8 30-8 15 8 30 8 15-8 30-8v36H0z" fill="${p.primary.hex}" fill-opacity=".55"/>'
                    '<path d="M0 60c15 0 15-6 30-6s15 6 30 6 15-6 30-6 15 6 30 6 15-6 30-6v24H0z" fill="${p.teal.hex}" fill-opacity=".45"/></svg>',
                    width: 144,
                    height: 72,
                    fit: BoxFit.fill,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pool.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink)),
                      const SizedBox(height: 2),
                      Text(
                        sub.length == 2 ? context.l10n.svcPoolSubtitle(sub[0], sub[1]) : sub.join(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(12, color: p.mut),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

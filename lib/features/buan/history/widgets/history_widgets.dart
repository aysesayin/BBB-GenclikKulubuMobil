import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_transaction.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_icons.dart';

/// "BUGÜN" / "DÜN" / "14 EKİM" gün başlığı metni.
String historyDayLabel(BuildContext context, DateTime day, {DateTime? now}) {
  final l = context.l10n;
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final diff = today.difference(day).inDays;
  if (diff == 0) return trUpper(l.buanHistoryToday);
  if (diff == 1) return trUpper(l.buanHistoryYesterday);
  final locale = Localizations.localeOf(context).languageCode;
  return trUpper(DateFormat.MMMMd(locale).format(day));
}

/// Ay özeti: yeşil kazanç + mor harcama kartları.
class HistorySummary extends StatelessWidget {
  const HistorySummary({super.key, required this.summary});

  final BuanMonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final month = DateFormat.MMMM(Localizations.localeOf(context).languageCode).format(summary.month);
    return Row(
      children: [
        Expanded(
          child: _Card(label: l.buanHistoryMonthEarned(month), value: Fmt.signed(summary.earned), bg: p.grnS, fg: p.grnT),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Card(label: l.buanHistoryMonthSpent(month), value: Fmt.signed(-summary.spent.abs()), bg: p.purS, fg: p.purT),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.value, required this.bg, required this.fg});

  final String label, value;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.tile)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.body(12, weight: FontWeight.w800, color: fg),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: AppTypography.number(24, color: fg)),
          ),
        ],
      ),
    ),
  );
}

class HistoryDayHeader extends StatelessWidget {
  const HistoryDayHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Semantics(
      header: true,
      child: Text(
        label,
        style: AppTypography.body(13, weight: FontWeight.w900, color: context.palette.mut).copyWith(letterSpacing: .6),
      ),
    ),
  );
}

/// Zaman çizelgesi satırı: + yeşil yukarı ok / − mor aşağı ok ve işaret karakteri.
class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.tx});

  final BuanTransaction tx;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final earn = tx.isEarn;
    final c = earn ? p.grnT : p.purT;
    final amount = Fmt.number(tx.amount.abs());
    final time = Fmt.time(tx.createdAt.toLocal(), Localizations.localeOf(context).languageCode);
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: earn ? p.grnS : p.purS, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: AppIcon(earn ? BuanIcons.arrowUp : BuanIcons.arrowDown, size: 20, color: c, strokeWidth: 2.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(time, style: AppTypography.body(12, color: p.mut)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: earn ? l.buanHistoryEarnSemantics(amount) : l.buanHistorySpendSemantics(amount),
              excludeSemantics: true,
              child: Text(Fmt.signed(tx.amount), maxLines: 1, softWrap: false, style: AppTypography.number(16, color: c)),
            ),
          ],
        ),
      ),
    );
  }
}

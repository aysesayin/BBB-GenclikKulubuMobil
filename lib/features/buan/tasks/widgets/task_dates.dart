/// Bugünden [d]'ye kalan takvim günü (0 = bugün, geçmiş → 0).
int daysUntil(DateTime d, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final local = d.toLocal();
  return DateTime(local.year, local.month, local.day).difference(today).inDays.clamp(0, 9999);
}

/// API tarih biçimi: yyyy-MM-dd (yerel gün).
String isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

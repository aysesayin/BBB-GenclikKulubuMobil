import 'package:freezed_annotation/freezed_annotation.dart';

part 'buan_transaction.freezed.dart';
part 'buan_transaction.g.dart';

/// Geçmiş filtresi; sorguda `type=all|earn|spend`.
enum BuanTxFilter { all, earn, spend }

/// Tek BUAN hareketi. [amount] işaretli: + kazanç, − harcama.
@freezed
abstract class BuanTransaction with _$BuanTransaction {
  const BuanTransaction._();

  const factory BuanTransaction({required String id, required String title, required int amount, required DateTime createdAt}) =
      _BuanTransaction;

  factory BuanTransaction.fromJson(Map<String, dynamic> json) => _$BuanTransactionFromJson(json);

  bool get isEarn => amount >= 0;
}

@freezed
abstract class BuanMonthSummary with _$BuanMonthSummary {
  const factory BuanMonthSummary({required DateTime month, @Default(0) int earned, @Default(0) int spent}) = _BuanMonthSummary;

  factory BuanMonthSummary.fromJson(Map<String, dynamic> json) => _$BuanMonthSummaryFromJson(json);
}

/// `GET /buan/transactions?type=&cursor=` — imleçli sayfa.
@freezed
abstract class BuanTransactionPage with _$BuanTransactionPage {
  const factory BuanTransactionPage({
    @Default(<BuanTransaction>[]) List<BuanTransaction> items,
    String? nextCursor,

    /// Yalnız ilk sayfada: bu ayın kazanç / harcama toplamı.
    BuanMonthSummary? summary,
  }) = _BuanTransactionPage;

  factory BuanTransactionPage.fromJson(Map<String, dynamic> json) => _$BuanTransactionPageFromJson(json);
}

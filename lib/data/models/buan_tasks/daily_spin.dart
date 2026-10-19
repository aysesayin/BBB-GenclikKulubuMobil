import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_spin.freezed.dart';
part 'daily_spin.g.dart';

/// Çark dilimi. Değerler panelden gelir (kodda sabit değil).
@freezed
abstract class SpinSlice with _$SpinSlice {
  const factory SpinSlice({required String id, required int amount}) = _SpinSlice;

  factory SpinSlice.fromJson(Map<String, dynamic> json) => _$SpinSliceFromJson(json);
}

/// `GET /buan/daily-spin` — bugünkü hak durumu ve çark dilimleri.
@freezed
abstract class DailySpinStatus with _$DailySpinStatus {
  const factory DailySpinStatus({
    @Default(false) bool available,
    @Default(<SpinSlice>[]) List<SpinSlice> slices,

    /// Bir sonraki hakkın açılacağı an (sunucu saati).
    DateTime? nextSpinAt,

    /// Bugün kazanılan tutar (hak kullanıldıysa).
    int? lastAmount,
  }) = _DailySpinStatus;

  factory DailySpinStatus.fromJson(Map<String, dynamic> json) => _$DailySpinStatusFromJson(json);
}

/// `POST /buan/daily-spin` — sonuç SUNUCUDA belirlenir; çark yalnız gösterir.
@freezed
abstract class SpinResult with _$SpinResult {
  const factory SpinResult({required int sliceIndex, required int amount, int? balance, DateTime? nextSpinAt}) = _SpinResult;

  factory SpinResult.fromJson(Map<String, dynamic> json) => _$SpinResultFromJson(json);
}

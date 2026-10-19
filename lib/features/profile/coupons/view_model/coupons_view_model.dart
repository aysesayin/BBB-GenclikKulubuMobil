import '../../../../core/base/base_view_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/profile/coupon.dart';
import '../../../../data/repositories/coupon_repository.dart';

class CouponsData {
  const CouponsData({required this.wallet, required this.movements});

  final CouponWallet wallet;
  final List<CouponMovement> movements;
}

enum CouponIssue { emptyCode, invalid, alreadyAdded }

/// I5 · Kuponlarım: bakiye, kupon listesi, kodla ekleme, hareketler.
/// Hareketler alınamazsa ekran yine açılır (liste boş).
class CouponsViewModel extends LoadableViewModel<CouponsData> {
  CouponsViewModel(this._repo);

  final CouponRepository _repo;

  bool _redeeming = false;
  bool get redeeming => _redeeming;

  CouponIssue? _issue;
  CouponIssue? get issue => _issue;

  AppException? _error;
  AppException? get error => _error;

  @override
  Future<ApiResult<CouponsData>> fetch() async {
    final walletFuture = _repo.wallet();
    final movesFuture = _repo.movements();
    final wallet = await walletFuture;
    final moves = await movesFuture;
    return switch (wallet) {
      Failure(:final error) => Failure(error),
      Success(:final data, :final fromCache) => Success(
        CouponsData(wallet: data, movements: _sorted(moves.dataOrNull ?? const [])),
        fromCache: fromCache,
      ),
    };
  }

  static List<CouponMovement> _sorted(List<CouponMovement> list) => [...list]..sort((a, b) => b.date.compareTo(a.date));

  /// Kod normalizasyonu: boşluklar atılır, Türkçe büyük harf.
  static String normalize(String code) => trUpper(code.replaceAll(RegExp(r'\s'), ''));

  /// Başarılıysa eklenen kupon döner; bakiye ve hareketler yeniden yüklenir.
  Future<Coupon?> redeem(String raw) async {
    if (_redeeming) return null;
    final code = normalize(raw);
    _error = null;
    _issue = code.isEmpty ? CouponIssue.emptyCode : null;
    if (_issue != null) {
      notify();
      return null;
    }
    _redeeming = true;
    notify();
    final result = await _repo.redeem(code);
    _redeeming = false;
    if (isDisposed) return null;
    switch (result) {
      case Success(:final data):
        await load();
        return data;
      case Failure(:final error):
        _issue = switch (error) {
          NotFoundException() || ValidationException() => CouponIssue.invalid,
          ConflictException() => CouponIssue.alreadyAdded,
          _ => null,
        };
        if (_issue == null) _error = error;
        notify();
        return null;
    }
  }

  void clearIssue() {
    if (_issue == null && _error == null) return;
    _issue = null;
    _error = null;
    notify();
  }
}

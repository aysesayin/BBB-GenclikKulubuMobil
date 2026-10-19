import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../data/repositories/opportunity_repository.dart';

/// Yapışkan CTA'nın durumu.
enum ClaimCta { available, claimed, ineligible, soldOut, expired }

/// C2 · Fırsat detayı: favori (iyimser), akordeon, yakalama.
class OpportunityDetailViewModel extends LoadableViewModel<OpportunityDetail> {
  OpportunityDetailViewModel(this._repo, this.id, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final OpportunityRepository _repo;
  final String id;
  final DateTime Function() _now;

  bool? _favorite;
  bool _claiming = false;
  bool get claiming => _claiming;

  ClaimResult? _claim;

  /// Bu oturumda yakalanan kod (CTA → "Kodumu göster").
  ClaimResult? get claim => _claim;

  /// Açık akordeon bölümü (-1 → hepsi kapalı). Tasarımda ilk bölüm açık gelir.
  int _expanded = 0;
  int get expanded => _expanded;

  @override
  Future<ApiResult<OpportunityDetail>> fetch() => _repo.detail(id);

  OpportunityDetail? get detail => state.dataOrNull;

  bool get isFavorite => _favorite ?? detail?.summary.isFavorite ?? false;

  ClaimCta get cta {
    final d = detail;
    if (d == null) return ClaimCta.available;
    if (_claim != null || d.isClaimed) return ClaimCta.claimed;
    if (!d.eligible) return ClaimCta.ineligible;
    if (d.soldOut) return ClaimCta.soldOut;
    if (d.summary.endsAt.isBefore(_now())) return ClaimCta.expired;
    return ClaimCta.available;
  }

  int daysLeft() => detail?.summary.daysLeft(_now()) ?? 0;
  bool get endingSoon => detail?.summary.isEndingSoon(_now()) ?? false;

  void toggleSection(int i) {
    _expanded = _expanded == i ? -1 : i;
    notify();
  }

  Future<AppException?> toggleFavorite() async {
    final value = !isFavorite;
    _favorite = value;
    notify();
    final r = await _repo.setFavorite(id, value: value);
    if (r case Failure(:final error)) {
      _favorite = !value;
      notify();
      return error;
    }
    return null;
  }

  /// Kodu üretir. Görünüm başarıda Yakalandı ekranına geçer, hatada mesaj gösterir.
  Future<ApiResult<ClaimResult>> claimNow() async {
    if (_claiming) return const Failure(CancelledException());
    _claiming = true;
    notify();
    final r = await _repo.claim(id);
    if (isDisposed) return r;
    if (r case Success(:final data)) _claim = data;
    _claiming = false;
    notify();
    return r;
  }
}

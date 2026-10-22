import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/repositories/opportunity_repository.dart';

/// Kullanılan fırsatı puanlama (1–5 yıldız + isteğe bağlı yorum) → "Fırsat Kullan Kazan" BUAN'ı.
class RatingViewModel extends BaseViewModel {
  RatingViewModel(this._repo, this.opportunityId);

  final OpportunityRepository _repo;
  final String opportunityId;

  static const maxStars = 5;
  static const maxComment = 280;

  int _stars = 0;
  int get stars => _stars;

  String _comment = '';
  String get comment => _comment;

  bool _submitting = false;
  bool get submitting => _submitting;

  RatingResult? _result;
  RatingResult? get result => _result;

  bool get canSubmit => _stars > 0 && !_submitting && _result == null;

  void setStars(int value) {
    final v = value.clamp(0, maxStars);
    if (v == _stars) return;
    _stars = v;
    notify();
  }

  void setComment(String value) {
    _comment = value.length > maxComment ? value.substring(0, maxComment) : value;
  }

  /// Başarıda [result] dolar; görünüm toast gösterir. Hata [AppException] olarak döner.
  Future<AppException?> submit() async {
    if (!canSubmit) return null;
    _submitting = true;
    notify();
    final r = await _repo.rate(opportunityId, stars: _stars, comment: _comment.trim().isEmpty ? null : _comment.trim());
    if (isDisposed) return null;
    _submitting = false;
    switch (r) {
      case Success(:final data):
        _result = data;
        notify();
        return null;
      case Failure(:final error):
        notify();
        return error;
    }
  }
}

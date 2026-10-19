import '../../../../core/base/base_view_model.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/profile/child_profile.dart';
import '../../../../data/repositories/profile_repository.dart';

enum ChildFormIssue { mernisFailed, alreadyAdded, overAge }

/// I4 · Çocuk işlemleri: liste + TCKN/doğum tarihiyle ekleme (MERNİS sunucuda, <18 hem
/// istemcide hem sunucuda). KVKK: TCKN yalnız istek anında kullanılır, VM'de tutulmaz.
class ChildrenViewModel extends LoadableViewModel<List<ChildProfile>> {
  ChildrenViewModel(this._repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ProfileRepository _repo;
  final DateTime Function() _clock;

  static const adultAge = 18;

  bool _submitting = false;
  bool get submitting => _submitting;

  ValidationIssue? _tcknIssue;
  ValidationIssue? get tcknIssue => _tcknIssue;

  /// Tarih alanı hatası: biçim / gelecek tarih.
  bool _dateInvalid = false, _dateFuture = false;
  bool get dateInvalid => _dateInvalid;
  bool get dateFuture => _dateFuture;

  ChildFormIssue? _issue;
  ChildFormIssue? get issue => _issue;

  AppException? _error;
  AppException? get error => _error;

  @override
  Future<ApiResult<List<ChildProfile>>> fetch() => _repo.children();

  /// "GG.AA.YYYY" → tarih; geçersizse null.
  static DateTime? parseDate(String text) {
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(text.trim());
    if (m == null) return null;
    final d = int.parse(m[1]!), mo = int.parse(m[2]!), y = int.parse(m[3]!);
    final date = DateTime(y, mo, d);
    if (date.year != y || date.month != mo || date.day != d || y < 1900) return null;
    return date;
  }

  /// Başarılıysa eklenen çocuk döner.
  Future<ChildProfile?> add({required String tckn, required String birthDate}) async {
    if (_submitting) return null;
    final digits = tckn.replaceAll(RegExp(r'\D'), '');
    final date = parseDate(birthDate);
    final today = _clock();
    _tcknIssue = Validators.tckn(digits);
    _dateInvalid = date == null;
    _dateFuture = date != null && date.isAfter(today);
    _issue = (date != null && !_dateFuture && Validators.ageOn(date, today) >= adultAge) ? ChildFormIssue.overAge : null;
    _error = null;
    if (_tcknIssue != null || _dateInvalid || _dateFuture || _issue != null || date == null) {
      notify();
      return null;
    }
    _submitting = true;
    notify();
    final result = await _repo.addChild(tckn: digits, birthDate: date);
    _submitting = false;
    if (isDisposed) return null;
    switch (result) {
      case Success(:final data):
        final list = state.dataOrNull ?? const <ChildProfile>[];
        state = ViewSuccess([...list.where((c) => c.id != data.id), data]);
        return data;
      case Failure(:final error):
        _issue = switch (error) {
          ForbiddenException() => ChildFormIssue.overAge,
          ConflictException() => ChildFormIssue.alreadyAdded,
          ValidationException() || NotFoundException() => ChildFormIssue.mernisFailed,
          _ => null,
        };
        if (_issue == null) _error = error;
        notify();
        return null;
    }
  }

  void clearIssues() {
    if (_tcknIssue == null && !_dateInvalid && !_dateFuture && _issue == null && _error == null) return;
    _tcknIssue = null;
    _dateInvalid = _dateFuture = false;
    _issue = null;
    _error = null;
    notify();
  }
}

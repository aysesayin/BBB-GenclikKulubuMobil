import '../../../../core/base/base_view_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/repositories/profile_repository.dart';

/// Şifre değiştirme formu.
class PasswordChangeViewModel extends BaseViewModel {
  PasswordChangeViewModel(this._repo);

  final ProfileRepository _repo;

  bool _busy = false;
  bool get busy => _busy;

  ValidationIssue? currentIssue, nextIssue;
  bool mismatch = false;

  AppException? _error;
  AppException? get error => _error;

  Future<bool> submit({required String current, required String next, required String repeat}) async {
    if (_busy) return false;
    currentIssue = Validators.required(current);
    nextIssue = Validators.password(next);
    mismatch = nextIssue == null && next != repeat;
    _error = null;
    if (currentIssue != null || nextIssue != null || mismatch) {
      notify();
      return false;
    }
    _busy = true;
    notify();
    final result = await _repo.changePassword(current: current, next: next);
    _busy = false;
    if (result case Failure(:final error)) _error = error;
    notify();
    return result is Success;
  }
}

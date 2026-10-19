import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../data/models/profile/profile_stats.dart';
import '../../../data/models/profile/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';

/// Profil ekranı verisi: kullanıcı + sayaçlar.
class ProfileOverview {
  const ProfileOverview({required this.user, required this.stats});

  final UserProfile user;
  final ProfileStats stats;
}

/// I1 · Profil. `GET /users/me` zorunlu; `GET /users/me/stats` hata verirse sayaçlar boş gösterilir.
class ProfileViewModel extends LoadableViewModel<ProfileOverview> {
  ProfileViewModel(this._repo);

  final ProfileRepository _repo;

  bool _avatarBusy = false;
  bool get avatarBusy => _avatarBusy;

  @override
  Future<ApiResult<ProfileOverview>> fetch() async {
    final meFuture = _repo.me();
    final statsFuture = _repo.stats();
    final me = await meFuture;
    final stats = await statsFuture;
    return switch (me) {
      Failure(:final error) => Failure(error),
      Success(data: final user, fromCache: final meCached) => Success(
        ProfileOverview(user: user, stats: stats.dataOrNull ?? const ProfileStats()),
        fromCache: meCached || (stats is Success<ProfileStats> && stats.fromCache),
      ),
    };
  }

  /// Avatar yükler ve profili sessizce yeniler. null → başarı.
  Future<AppException?> uploadAvatar({required String path, required String fileName}) async {
    if (_avatarBusy) return null;
    _avatarBusy = true;
    notify();
    final result = await _repo.uploadAvatar(path: path, fileName: fileName);
    _avatarBusy = false;
    if (isDisposed) return null;
    if (result case Failure(:final error)) {
      notify();
      return error;
    }
    await load();
    return null;
  }

  /// Sunucu oturumunu kapatmayı dener (hata yok sayılır), sonra yerel oturumu temizler.
  Future<void> signOut(SessionController session) async {
    await _repo.logout();
    await session.signOut();
  }
}

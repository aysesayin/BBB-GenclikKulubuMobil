import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../core/router/routes.dart';
import '../../../data/models/buan/buan_task.dart';
import '../../../data/models/buan/buan_wallet.dart';
import '../../../data/repositories/buan_repository.dart';

/// E1 ana ekranın tek seferde yüklenen verisi.
class BuanHomeData {
  const BuanHomeData({required this.wallet, required this.level, required this.streak, required this.groups});

  final BuanWallet wallet;
  final BuanLevel level;
  final BuanStreak streak;
  final List<BuanTaskGroup> groups;
}

/// E1 · BUAN ana + Kazan. Cüzdan, seviye, seri ve görevleri paralel yükler;
/// paylaşılan bakiyeyi dinler (takas sonrası hero eski → yeni sayar).
class BuanViewModel extends LoadableViewModel<BuanHomeData> {
  BuanViewModel(this._repo) {
    _repo.balance.addListener(notify);
  }

  final BuanRepository _repo;

  /// Güncel bakiye: paylaşılan değer, yoksa yüklenen cüzdan.
  int get balance => _repo.balance.value ?? state.dataOrNull?.wallet.balance ?? 0;

  @override
  Future<ApiResult<BuanHomeData>> fetch() async {
    final results = await Future.wait<ApiResult<Object>>([_repo.wallet(), _repo.level(), _repo.streak(), _repo.tasks()]);
    for (final r in results) {
      if (r case Failure(:final error)) return Failure(error);
    }
    final fromCache = results.any((r) => r is Success<Object> && r.fromCache);
    return Success(
      BuanHomeData(
        wallet: results[0].dataOrNull! as BuanWallet,
        level: results[1].dataOrNull! as BuanLevel,
        streak: results[2].dataOrNull! as BuanStreak,
        groups: (results[3].dataOrNull! as List<BuanTaskGroup>).where((g) => g.tasks.isNotEmpty).toList(),
      ),
      fromCache: fromCache,
    );
  }

  /// Görev kartının gideceği ekran; null → kurallar sheet'i açılır
  /// (kilitli, tamamlanmış ya da uygulama içi akışı olmayan görevler).
  static String? routeFor(BuanTask task) {
    if (task.isLocked || task.isDone) return null;
    return switch (task.type) {
      BuanTaskType.watch => Routes.watchEarn,
      BuanTaskType.steps => Routes.steps,
      BuanTaskType.quiz => Routes.quiz,
      BuanTaskType.invite => Routes.invite,
      BuanTaskType.photo => Routes.photoReport,
      BuanTaskType.spin => Routes.dailySpin,
      BuanTaskType.qr => Routes.qrScan,
      // TODO(varsayım): Takip Et / Gönül Dostu / BİKO / Fikrin ile Kazan / Fırsat Kullan için
      // uygulama içi akış tasarlanmadı; şimdilik kurallar sheet'i gösteriliyor.
      BuanTaskType.follow ||
      BuanTaskType.volunteer ||
      BuanTaskType.biko ||
      BuanTaskType.idea ||
      BuanTaskType.useOpportunity ||
      BuanTaskType.unknown => null,
    };
  }

  @override
  void dispose() {
    _repo.balance.removeListener(notify);
    super.dispose();
  }
}

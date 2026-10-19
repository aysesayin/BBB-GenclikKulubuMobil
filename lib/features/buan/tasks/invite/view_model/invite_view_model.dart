import 'dart:async';
import 'dart:math' as math;

import '../../../../../core/base/base_view_model.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/api_result.dart';
import '../../../../../data/models/buan_tasks/referral.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';

/// E11 · Davet Et. Kod + paylaşım bağlantısı + davet edilenlerin durumu.
class InviteViewModel extends LoadableViewModel<Referral> {
  InviteViewModel(this._repo, {this.copiedDuration = const Duration(seconds: 2)});

  final ReferralRepository _repo;
  final Duration copiedDuration;

  bool _copied = false;
  Timer? _copiedTimer;

  Referral? get referral => state.dataOrNull;

  /// `{deepLinkBase}/davet/{kod}` — uygulama `/davet/:code` ile kayda yönlendirir.
  String get link => referral == null ? '' : '${ApiConfig.deepLinkBase}/davet/${Uri.encodeComponent(referral!.code)}';

  bool get copied => _copied;
  bool get limitReached => referral != null && referral!.weeklyUsed >= referral!.weeklyLimit;
  int get remainingThisWeek => referral == null ? 0 : math.max(0, referral!.weeklyLimit - referral!.weeklyUsed);

  @override
  Future<ApiResult<Referral>> fetch() => _repo.referral();

  /// Görünüm panoya yazdıktan sonra çağırır: ikon 2 sn ✓ olur.
  void markCopied() {
    _copied = true;
    _copiedTimer?.cancel();
    _copiedTimer = Timer(copiedDuration, () {
      _copied = false;
      notify();
    });
    notify();
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

/// Analitik olayları (spec §13).
enum AnalyticsEvent {
  onboardingComplete('onboarding_complete'),
  registerSuccess('register_success'),
  opportunityClaim('opportunity_claim'),
  taskComplete('task_complete'),
  rewardRedeem('reward_redeem'),
  qrCheckin('qr_checkin'),
  streakExtend('streak_extend'),
  shareReferral('share_referral');

  const AnalyticsEvent(this.key);
  final String key;
}

abstract interface class AnalyticsService {
  Future<void> log(AnalyticsEvent event, [Map<String, Object> params]);
  Future<void> screen(String name);
}

/// TODO(varsayım): firebase_analytics, Firebase proje dosyaları (google-services.json /
/// GoogleService-Info.plist) eklendiğinde FirebaseAnalyticsService ile değiştirilecek.
class DebugAnalyticsService implements AnalyticsService {
  @override
  Future<void> log(AnalyticsEvent event, [Map<String, Object> params = const {}]) async {
    if (kDebugMode) debugPrint('[analytics] ${event.key} $params');
  }

  @override
  Future<void> screen(String name) async {
    if (kDebugMode) debugPrint('[analytics] screen $name');
  }
}

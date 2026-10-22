import 'package:bbb_genclik_kulubu_app/core/session/session_controller.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/account_settings.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/delete_request.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/profile_stats.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/support.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/user_profile.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/coupon_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/profile_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/support_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/settings/view_model/biometric_login.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockCouponRepository extends Mock implements CouponRepository {}

class MockSupportRepository extends Mock implements SupportRepository {}

class MockBiometricLogin extends Mock implements BiometricLogin {}

class MockSessionController extends Mock implements SessionController {}

void registerProfileFallbacks() {
  registerFallbackValue(const NotificationPrefs());
  registerFallbackValue(ContactKind.phone);
  registerFallbackValue(SupportType.oneri);
  registerFallbackValue(DateTime(2000));
}

const demoUser = UserProfile(
  id: 'usr-demo',
  firstName: 'Ayşe',
  lastName: 'Su',
  tcknMasked: '1234*****90',
  memberNo: '0016 4821',
  level: 3,
  levelName: 'Kâşif',
  phoneMasked: '0532 *** ** 90',
  emailMasked: 'a***e@ornek.com',
  buanBalance: 12450,
  streak: 7,
);

const demoStats = ProfileStats(
  totalBuanEarned: 24350,
  eventsAttended: 9,
  opportunitiesUsed: 7,
  districtRank: 14,
  badgeCount: 7,
  pendingPayments: 1,
  openSurveys: 2,
);

/// Mock `users.me.delete-request.post.json` ile aynı makbuz.
final demoReceipt = DeleteRequestReceipt(requestId: 'del-demo', requestNo: 'KVKK-2026-048213', processUntil: DateTime(2026, 11, 21));

/// Algoritmaya uygun örnek TCKN.
const validTckn = '10000000146';

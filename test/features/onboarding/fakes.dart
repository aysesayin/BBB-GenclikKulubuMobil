import 'package:bbb_genclik_kulubu_app/core/session/session_controller.dart';
import 'package:bbb_genclik_kulubu_app/core/storage/cache_store.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/ui_prefs_controller.dart';
import 'package:bbb_genclik_kulubu_app/data/models/app/app_config.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/auth_requests.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/auth_session.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/first_day_task.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/app_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/auth_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/interests_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/auth/biometric_authenticator.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/permission_gateway.dart';
import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSession extends Mock implements SessionController {}

class MockAppRepository extends Mock implements AppRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockInterestsRepository extends Mock implements InterestsRepository {}

class MockBiometric extends Mock implements BiometricAuthenticator {}

class MockPermissionGateway extends Mock implements PermissionGateway {}

const demoSession = AuthSession(
  accessToken: 'a',
  refreshToken: 'r',
  user: AuthUser(id: 'usr-demo', firstName: 'Ayşe', lastName: 'Su'),
  welcome: WelcomeCard(
    memberNo: '0016 4821',
    levelName: 'Sv 1 · Çaylak',
    checkInCode: '8315',
    qrToken: 'qr',
    welcomeBonus: 500,
    onboardingBonus: 100,
    inviteReward: 2000,
  ),
);

/// `GET /auth/first-day` taklidi (mock dosyasıyla aynı 3 görev).
const firstDayTasks = [
  FirstDayTask(id: 'fd-first-deal', title: 'İlk fırsatını yakala', reward: 100, icon: 'tag', route: '/firsatlar'),
  FirstDayTask(id: 'fd-qr-scan', title: 'QR okut', reward: 500, icon: 'qr', route: '/qr-okut'),
  FirstDayTask(id: 'fd-invite', title: 'Bir arkadaş davet et', reward: 2000, icon: 'gift', route: '/buan/davet'),
];

void registerAuthFallbacks() {
  registerFallbackValue(const LoginRequest(method: LoginMethod.tckn, identifier: '', password: ''));
  registerFallbackValue(const RegisterRequest(tckn: '', birthDate: '', phone: '', otpToken: '', acceptedConsents: []));
  registerFallbackValue(const SessionUser(id: '', firstName: '', lastName: ''));
  registerFallbackValue(LoginMethod.tckn);
  registerFallbackValue(OnbPermission.location);
  registerFallbackValue(<String>{});
}

/// Oturum taklidi: signIn / markOnboardingSeen / continueAsGuest başarılı.
MockSession stubSession({bool authenticated = false, bool onboardingSeen = false}) {
  final s = MockSession();
  when(s.restore).thenAnswer((_) async {});
  when(() => s.isAuthenticated).thenReturn(authenticated);
  when(() => s.onboardingSeen).thenReturn(onboardingSeen);
  when(s.markOnboardingSeen).thenAnswer((_) async {});
  when(s.continueAsGuest).thenReturn(null);
  when(() => s.user).thenReturn(const SessionUser(id: 'usr-demo', firstName: 'Ayşe', lastName: 'Su'));
  when(
    () => s.signIn(
      accessToken: any(named: 'accessToken'),
      refreshToken: any(named: 'refreshToken'),
      user: any(named: 'user'),
    ),
  ).thenAnswer((_) async {});
  return s;
}

MockAppRepository stubApp([AppConfig config = const AppConfig()]) {
  final a = MockAppRepository();
  when(() => a.current).thenReturn(config);
  return a;
}

/// Kolay Mod denetleyicisi (cihaz kaydı bellekte). Widget testlerinde `context.easyMode` için şart.
Future<UiPrefsController> testPrefs({bool easy = false}) async {
  SharedPreferences.setMockInitialValues({'pref.easyMode': easy});
  return UiPrefsController(CacheStore(await SharedPreferences.getInstance()));
}

/// Ağacı [UiPrefsController] ile sarar.
Widget withPrefs(UiPrefsController prefs, Widget child) => ChangeNotifierProvider<UiPrefsController>.value(value: prefs, child: child);

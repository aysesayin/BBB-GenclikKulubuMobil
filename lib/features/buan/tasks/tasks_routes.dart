import 'package:go_router/go_router.dart';

import '../../../core/router/navigator_keys.dart';
import 'invite/view/invite_view.dart';
import 'photo_report/view/photo_report_view.dart';
import 'quiz/view/quiz_view.dart';
import 'spin/view/daily_spin_view.dart';
import 'steps/view/steps_view.dart';
import 'watch/view/watch_earn_view.dart';

/// E7–E12 görev ekranları — `/buan` altında, tam ekran (sekme çubuğu yok).
final List<RouteBase> buanTaskBranchRoutes = [
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'sans', builder: (_, _) => const DailySpinView()),
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'izle', builder: (_, _) => const WatchEarnView()),
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'adim', builder: (_, _) => const StepsView()),
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'quiz', builder: (_, _) => const QuizView()),
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'davet', builder: (_, _) => const InviteView()),
  GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'cek', builder: (_, _) => const PhotoReportView()),
];

import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import 'view/qr_scan_view.dart';
import 'view/turnstile_view.dart';

/// Tam ekran (kök navigator): QR Okut Kazan · Turnike modu.
final List<RouteBase> cardRootRoutes = [
  GoRoute(path: Routes.qrScan, builder: (_, _) => const QrScanView()),
  GoRoute(path: Routes.turnstile, builder: (_, _) => const TurnstileView()),
];

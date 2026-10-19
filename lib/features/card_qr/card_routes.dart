import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import 'view/qr_scan_view.dart';

/// Tam ekran (kök navigator): QR Okut Kazan.
final List<RouteBase> cardRootRoutes = [GoRoute(path: Routes.qrScan, builder: (_, _) => const QrScanView())];

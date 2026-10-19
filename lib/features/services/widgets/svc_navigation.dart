import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';

/// Seans ekranını açar. Rota korumalıysa (bkz. [Routes.isProtected]) misafire
/// sert yönlendirme yerine yumuşak duvar (AuthGate) gösterilir.
void openSessions(BuildContext context, String itemId) {
  Haptics.selection();
  final route = Routes.sessions(itemId);
  final guest = context.read<SessionController>().isGuest;
  if (guest && Routes.isProtected(route)) {
    AuthGate.show(context);
    return;
  }
  context.push(route);
}

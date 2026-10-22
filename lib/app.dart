import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/di/locator.dart';
import 'core/router/app_router.dart';
import 'core/services/connectivity_service.dart';
import 'core/session/session_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/ui_prefs_controller.dart';
import 'data/repositories/app_repository.dart';
import 'l10n/l10n.dart';

class GenclikApp extends StatefulWidget {
  const GenclikApp({super.key});

  @override
  State<GenclikApp> createState() => _GenclikAppState();
}

class _GenclikAppState extends State<GenclikApp> {
  late final GoRouter _router = createRouter(sl<SessionController>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionController>.value(value: sl<SessionController>()),
          ChangeNotifierProvider<ThemeController>.value(value: sl<ThemeController>()),
          ChangeNotifierProvider<UiPrefsController>.value(value: sl<UiPrefsController>()),
          ValueListenableProvider<bool>.value(value: sl<ConnectivityService>().online),
          Provider<AppRepository>.value(value: sl<AppRepository>()),
        ],
        child: Selector<ThemeController, ThemeMode>(
          selector: (_, t) => t.mode,
          builder: (context, mode, _) => MaterialApp.router(
            onGenerateTitle: (ctx) => ctx.l10n.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            routerConfig: _router,
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // Dinamik yazı boyutu desteklenir; kart düzenleri bozulmasın diye üst sınır 1.35.
              // Kolay Mod: +%20 yazı ve animasyonlar kapalı (MediaQuery.disableAnimations → context.reduceMotion).
              final mq = MediaQuery.of(context);
              final prefs = context.watch<UiPrefsController>();
              final base = mq.textScaler.clamp(maxScaleFactor: 1.35);
              final scaler = prefs.easyMode ? TextScaler.linear((base.scale(1) * prefs.textScale).clamp(1.2, 1.5)) : base;
              return MediaQuery(
                data: mq.copyWith(textScaler: scaler, disableAnimations: mq.disableAnimations || prefs.easyMode),
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        ),
      );
}

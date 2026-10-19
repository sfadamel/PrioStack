import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/logging/app_logger.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/priostack_providers.dart';
import 'presentation/screens/cockpit_screen.dart';
import 'presentation/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture automatique de toutes les erreurs de rendu/framework Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'FlutterError interceptée',
      error: details.exception,
      stackTrace: details.stack,
      tag: 'FlutterFramework',
    );
  };

  // Capture automatique des erreurs asynchrones non gérées (Zone / PlatformDispatcher)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.error(
      'Erreur asynchrone non gérée',
      error: error,
      stackTrace: stack,
      tag: 'PlatformDispatcher',
    );
    return true;
  };

  // Remplacement de l'écran rouge de debug par un widget propre qui journalise l'erreur
  ErrorWidget.builder = (FlutterErrorDetails details) {
    AppLogger.error(
      'Erreur de rendu Widget (ErrorWidget)',
      error: details.exception,
      stackTrace: details.stack,
      tag: 'ErrorWidget',
    );
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonAmber.withValues(alpha: 0.5)),
        ),
        child: Text(
          'Rafraîchissement en cours…',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ),
    );
  };

  AppLogger.info('Démarrage de PrioStack V1');

  runApp(
    const ProviderScope(
      child: PrioStackApp(),
    ),
  );
}

class PrioStackApp extends ConsumerWidget {
  const PrioStackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'PrioStack — Architect & Manager Call Stack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : (authState.isAuthenticated
              ? CockpitScreen(key: ValueKey(themeMode))
              : const LoginScreen()),
    );
  }
}

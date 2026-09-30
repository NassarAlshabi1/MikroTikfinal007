import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'core/app_dependencies.dart';
import 'core/app_messenger.dart';
import 'database/migration_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'mqtt_service.dart';
import 'services/app_logger.dart';
import 'services/secure_credentials_storage.dart';
import 'theme/app_theme.dart';
import 'theme/professional_theme.dart';

// Compatibility exports for integration tests and external launchers. New
// code should import the owning feature library directly.
export 'features/auth/presentation/login_screen.dart' show LoginScreen;
export 'features/dashboard/presentation/home_screen.dart'
    show HomeScreen, MikrotikMode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrapInfrastructure();

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => MqttService()),
          provider.ChangeNotifierProvider(
            create: (_) => AppTheme()..initialize(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

Future<void> _bootstrapInfrastructure() async {
  try {
    await initializeAppDependencies();
    AppLogger.info(
      'Isar database opened successfully',
      category: LogCategory.system,
    );

    await SecureCredentialsStorageContainer.instance
        .migrateFromSharedPreferences();
    await MigrationService.instance.migrateLegacyDataIfNeeded();
  } catch (error, stackTrace) {
    // A legacy migration must not make the login screen unavailable. The
    // migration remains retryable on the next application start.
    AppLogger.error(
      'Application bootstrap migration failed',
      error: error,
      stackTrace: stackTrace,
      category: LogCategory.system,
    );
  }

  AppLogger.info('App starting', category: LogCategory.system);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<AppTheme>(
      builder: (context, themeProvider, child) => MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'MikroTik Manager',
        theme: ProfessionalTheme.light,
        darkTheme: ProfessionalTheme.dark,
        themeMode: themeProvider.themeMode,
        home: const LoginScreen(),
      ),
    );
  }
}

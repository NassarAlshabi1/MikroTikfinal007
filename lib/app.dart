import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;

import 'core/app_runtime.dart';
import 'features/auth/presentation/login_screen.dart';
import 'mqtt_service.dart';
import 'providers/app_theme_provider.dart';
import 'theme/app_theme.dart';
import 'theme/professional_theme.dart';

/// Application composition root: legacy Provider services and Riverpod state
/// are installed once here rather than being wired together in the entrypoint.
class ApplicationRoot extends StatelessWidget {
  const ApplicationRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.ChangeNotifierProvider(create: (_) => MqttService()),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => AppTheme()..initialize(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  }
}

/// Material application shell. Riverpod providers are consumed below the
/// [ApplicationRoot] boundary.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeProvider).themeMode;
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'MikroTik Manager',
      theme: ProfessionalTheme.light,
      darkTheme: ProfessionalTheme.dark,
      themeMode: themeMode,
      home: const LoginScreen(),
      routes: {
        // The route remains available after a session replaces the initial
        // login route, so logout returns to a fresh authentication screen.
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}

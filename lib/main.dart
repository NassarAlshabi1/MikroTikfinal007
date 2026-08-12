import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/mqtt_service_provider.dart';
import 'l10n/app_localizations.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mqttService = ref.watch(mqttServiceProvider);

    return MaterialApp(
      title: 'MikroTik Manager',
      theme: AppTheme.darkTheme,
      home: mqttService.isConnected
          ? const HomeScreen()
          : const LoginScreen(),
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('ar'),
      debugShowCheckedModeBanner: false,
    );
  }
}

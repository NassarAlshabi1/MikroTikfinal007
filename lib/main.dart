import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'l10n/app_localizations.dart';
import 'login_screen.dart';
import 'mqtt_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MikroTikManagerApp()));
}

class MikroTikManagerApp extends StatelessWidget {
  const MikroTikManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة MikroTik',
      theme: AppTheme.darkTheme,
      scaffoldMessengerKey: mqttScaffoldMessengerKey,
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
      },
      supportedLocales: const [Locale('ar'), Locale('en')],
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

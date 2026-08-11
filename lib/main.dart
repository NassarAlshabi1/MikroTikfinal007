import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/mqtt_service_provider.dart';
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
      title: 'اداره الكروت',
      theme: AppTheme.darkTheme,
      home: mqttService.isConnected
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}

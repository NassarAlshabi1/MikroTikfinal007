import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_pages.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:mikronet/features/telegram/services/telegram_scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // مؤقّت إشعارات Telegram (يعمل أثناء فتح التطبيق) — لا يفعل شيئًا لو كان معطّلًا
  TelegramScheduler.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MikroNet',
      // الثيم الداكن المعتمد (MikroNet Dark)
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.login,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.3,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

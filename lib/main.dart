import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/app_pages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'myfont'
      ),
      initialRoute: AppRoutes.login, 
      getPages: AppPages.routes, 
      debugShowCheckedModeBanner: false,
    );
  }
}

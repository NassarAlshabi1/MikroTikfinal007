import 'package:flutter/material.dart';

class RemotePrintingSetupScreen extends StatefulWidget {
  const RemotePrintingSetupScreen({super.key});

  @override
  State<RemotePrintingSetupScreen> createState() => _RemotePrintingSetupScreenState();
}

class _RemotePrintingSetupScreenState extends State<RemotePrintingSetupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الطباعة عن بعد'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.print_outlined,
              size: 100,
              color: Color(0xFF00BCD4),
            ),
            SizedBox(height: 24),
            Text(
              'إعدادات الطباعة عن بعد',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'هذه الميزة قيد التطوير حالياً\nسيتم إضافة إعدادات الطباعة عن بعد قريباً',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF757575),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 24),
            Icon(
              Icons.construction,
              size: 48,
              color: Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }
}
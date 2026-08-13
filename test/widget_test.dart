import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/main.dart';

void main() {
  testWidgets('يعرض التطبيق نقطة الدخول الأساسية', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MikroTikManagerApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

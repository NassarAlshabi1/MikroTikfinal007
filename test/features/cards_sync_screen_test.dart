import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/cards_sync_screen.dart';

void main() {
  testWidgets('combined User Manager screen retains report source guidance',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CardsSyncScreen()),
    );

    expect(find.text('كروت User Manager'), findsOneWidget);
    expect(find.text('مزامنة الآن'), findsOneWidget);
    expect(find.textContaining('uptime-used'), findsOneWidget);
    expect(find.textContaining('إيرادات'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/features/sales_reports/presentation/sales_report_screen.dart';

void main() {
  testWidgets('explains the User Manager source before manual sync',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SalesReportScreen()),
    );

    expect(find.text('تقرير الكروت'), findsOneWidget);
    expect(find.text('مزامنة الآن'), findsOneWidget);
    expect(find.textContaining('uptime-used'), findsOneWidget);
    expect(find.textContaining('إيرادات'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/features/dashboard/presentation/dashboard_status_card.dart';
import 'package:mikrotik_manager/theme/professional_theme.dart';

void main() {
  group('DashboardStatusCard', () {
    testWidgets('renders a cached router summary without a router connection', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ProfessionalTheme.light,
          home: const DashboardStatusCard(
            dashboardStatus: {
              'cpuUsage': 24.5,
              'memoryUsage': 48,
              'dataDownloaded': 3.2,
              'dataUploaded': 1.1,
              'activeUsers': 7,
              'version': '7.16.2',
              'uptime': '2d 4h',
            },
            isLoadingStatus: false,
            isNetworkLinked: false,
            clientName: '',
            isRefreshing: false,
          ),
        ),
      );

      expect(find.text('حالة MikroTik'), findsOneWidget);
      expect(find.textContaining('7.16.2'), findsOneWidget);
      expect(find.text('24.5%'), findsOneWidget);
      expect(find.text('المستخدمون النشطون'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('shows a loading state before the first status arrives', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ProfessionalTheme.light,
          home: const DashboardStatusCard(
            dashboardStatus: null,
            isLoadingStatus: true,
            isNetworkLinked: false,
            clientName: '',
            isRefreshing: false,
          ),
        ),
      );

      expect(find.text('جاري تحديث حالة MikroTik...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

import 'dashboard_status.dart';

abstract interface class DashboardRepository {
  Future<DashboardStatus?> loadCachedStatus();

  Future<DashboardStatus> refreshStatus();

  Future<List<Map<String, dynamic>>> fetchUserManagerProfiles();

  Future<NetworkLinkStatus> loadNetworkLinkStatus();
}

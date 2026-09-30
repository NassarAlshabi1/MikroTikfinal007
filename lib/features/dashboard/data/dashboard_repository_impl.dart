import 'dart:convert';

import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mikrotik_connector.dart';
import '../../../services/user_manager_profile_parser.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_status.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  static const _profilesCommand = '/tool/user-manager/profile/print';

  @override
  Future<NetworkLinkStatus> loadNetworkLinkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLinked = prefs.getBool('is_network_linked') ?? false;
    if (!isLinked) return const NetworkLinkStatus(isLinked: false);

    final encoded = prefs.getString('qahtani_linked_data');
    if (encoded == null) return const NetworkLinkStatus(isLinked: true);
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return const NetworkLinkStatus(isLinked: true);
      final clientInfo = decoded['client_info'];
      final name = clientInfo is Map
          ? clientInfo['name']?.toString() ?? ''
          : '';
      return NetworkLinkStatus(isLinked: true, clientName: name);
    } on FormatException {
      return const NetworkLinkStatus(isLinked: true);
    }
  }

  @override
  Future<DashboardStatus?> loadCachedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('cached_dashboard_status') ??
        prefs.getString('cached_stats');
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return DashboardStatus.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<DashboardStatus> refreshStatus() async {
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      final resourceResponse = await client.talk(['/system/resource/print']);
      final resource = resourceResponse.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(resourceResponse.first);

      final interfaces = await client.talk([
        '/interface/print',
        '=.proplist=name,rx-byte,tx-byte',
        'stats',
      ]);
      var downloadedBytes = 0.0;
      var uploadedBytes = 0.0;
      for (final interface in interfaces) {
        downloadedBytes +=
            double.tryParse(interface['rx-byte']?.toString() ?? '') ?? 0;
        uploadedBytes +=
            double.tryParse(interface['tx-byte']?.toString() ?? '') ?? 0;
      }

      var activeUsers = 0;
      try {
        activeUsers =
            (await client.talk(['/ip/hotspot/active/print'])).length;
      } catch (_) {
        // Hotspot may be disabled while User Manager remains available.
      }

      final totalMemory =
          double.tryParse(resource['total-memory']?.toString() ?? '') ?? 0;
      final freeMemory =
          double.tryParse(resource['free-memory']?.toString() ?? '') ?? 0;
      final status = DashboardStatus(
        cpuUsage:
            double.tryParse(resource['cpu-load']?.toString() ?? '') ?? 0,
        memoryUsage: totalMemory <= 0
            ? 0
            : ((totalMemory - freeMemory) / totalMemory * 100),
        uptime: resource['uptime']?.toString() ?? 'غير متوفر',
        dataDownloadedMb: downloadedBytes / (1024 * 1024),
        dataUploadedMb: uploadedBytes / (1024 * 1024),
        activeUsers: activeUsers,
        version: resource['version']?.toString() ?? 'غير معروف',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_dashboard_status',
        jsonEncode(status.toJson()),
      );
      return status;
    } finally {
      MikrotikConnector.release(client);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserManagerProfiles() async {
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      var response = await client.talk([
        _profilesCommand,
        '=.proplist=.id,name,rate-limit,shared-users,session-timeout',
      ]);
      var profiles = _parseProfiles(response);
      if (profiles.isEmpty) {
        response = await client.talk([_profilesCommand]);
        profiles = _parseProfiles(response);
      }
      return profiles;
    } finally {
      MikrotikConnector.release(client);
    }
  }

  List<Map<String, dynamic>> _parseProfiles(List<dynamic> response) {
    return UserManagerProfileParser.parse(
      response
          .whereType<Map>()
          .map((profile) => Map<String, dynamic>.from(profile)),
    );
  }
}

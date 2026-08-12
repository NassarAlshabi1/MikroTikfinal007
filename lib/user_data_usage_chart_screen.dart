import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:router_os_client/router_os_client.dart';
import 'mikrotik_connector.dart';
import 'snackbar_helpers.dart';

class UserDataUsageChartScreen extends StatefulWidget {
  const UserDataUsageChartScreen({super.key});

  @override
  State<UserDataUsageChartScreen> createState() => _UserDataUsageChartScreenState();
}

class _UserDataUsageChartScreenState extends State<UserDataUsageChartScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _usersData = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final usersResponse = await client.talk([
        '/tool/user-manager/user/print',
        '=.proplist=username,upload-used,download-used,actual-profile,disabled',
      ]).timeout(const Duration(seconds: 10));

      _usersData = usersResponse.map((e) => Map<String, dynamic>.from(e)).toList();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل البيانات: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      client?.close();
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_selectedFilter == 'all') return _usersData;
    return _usersData.where((user) {
      if (_selectedFilter == 'active') return user['disabled'] != 'true';
      if (_selectedFilter == 'disabled') return user['disabled'] == 'true';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('استخدام البيانات للمستخدمين', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchUserData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchUserData,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredUsers = _filteredUsers;
    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_accounts, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('لا توجد بيانات', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('الكل'),
                selected: _selectedFilter == 'all',
                onSelected: (selected) {
                  if (selected) setState(() => _selectedFilter = 'all');
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('المفعل'),
                selected: _selectedFilter == 'active',
                onSelected: (selected) {
                  if (selected) setState(() => _selectedFilter = 'active');
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('المعطل'),
                selected: _selectedFilter == 'disabled',
                onSelected: (selected) {
                  if (selected) setState(() => _selectedFilter = 'disabled');
                },
              ),
            ],
          ),
        ),
        // Chart
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBarChart(theme, filteredUsers),
                const SizedBox(height: 24),
                _buildTopUsersList(theme, filteredUsers),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(ThemeData theme, List<Map<String, dynamic>> users) {
    // Take top 10 users by total data usage
    final sortedUsers = List.from(users)
      ..sort((a, b) {
        final aTotal = (double.tryParse(a['download-used']?.toString() ?? '0') ?? 0.0) +
            (double.tryParse(a['upload-used']?.toString() ?? '0') ?? 0.0);
        final bTotal = (double.tryParse(b['download-used']?.toString() ?? '0') ?? 0.0) +
            (double.tryParse(b['upload-used']?.toString() ?? '0') ?? 0.0);
        return bTotal.compareTo(aTotal);
      });

    final topUsers = sortedUsers.take(10).toList();
    if (topUsers.isEmpty) return const SizedBox.shrink();

    final maxValue = topUsers.map((user) {
      final download = double.tryParse(user['download-used']?.toString() ?? '0') ?? 0.0;
      final upload = double.tryParse(user['upload-used']?.toString() ?? '0') ?? 0.0;
      return (download + upload) / (1024 * 1024); // Convert to MB
    }).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: theme.primaryColor),
              const SizedBox(width: 12),
              const Text('أعلى 10 مستخدمين في استهلاك البيانات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final user = topUsers[group.x.toInt()];
                      final download = double.tryParse(user['download-used']?.toString() ?? '0') ?? 0.0;
                      final upload = double.tryParse(user['upload-used']?.toString() ?? '0') ?? 0.0;
                      final totalMB = (download + upload) / (1024 * 1024);
                      return BarTooltipItem(
                        '${totalMB.toStringAsFixed(1)} MB',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= topUsers.length) return const SizedBox.shrink();
                        final username = topUsers[value.toInt()]['username']?.toString() ?? '';
                        final shortName = username.length > 8 ? '${username.substring(0, 8)}...' : username;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            shortName,
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxValue > 0 ? maxValue / 5 : 20,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()} MB', style: const TextStyle(fontSize: 10, color: Colors.white70));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(topUsers.length, (index) {
                  final user = topUsers[index];
                  final download = double.tryParse(user['download-used']?.toString() ?? '0') ?? 0.0;
                  final upload = double.tryParse(user['upload-used']?.toString() ?? '0') ?? 0.0;
                  final downloadMB = download / (1024 * 1024);
                  final uploadMB = upload / (1024 * 1024);

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: downloadMB,
                        color: Colors.blue,
                        width: 12,
                      ),
                      BarChartRodData(
                        toY: uploadMB,
                        color: Colors.green,
                        width: 12,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('تحميل', Colors.blue),
              const SizedBox(width: 24),
              _buildLegendItem('رفع', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTopUsersList(ThemeData theme, List<Map<String, dynamic>> users) {
    final sortedUsers = List.from(users)
      ..sort((a, b) {
        final aTotal = (double.tryParse(a['download-used']?.toString() ?? '0') ?? 0.0) +
            (double.tryParse(a['upload-used']?.toString() ?? '0') ?? 0.0);
        final bTotal = (double.tryParse(b['download-used']?.toString() ?? '0') ?? 0.0) +
            (double.tryParse(b['upload-used']?.toString() ?? '0') ?? 0.0);
        return bTotal.compareTo(aTotal);
      });

    final topUsers = sortedUsers.take(20).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: theme.primaryColor),
              const SizedBox(width: 12),
              const Text('أعلى المستخدمين', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...topUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final download = double.tryParse(user['download-used']?.toString() ?? '0') ?? 0.0;
            final upload = double.tryParse(user['upload-used']?.toString() ?? '0') ?? 0.0;
            final totalMB = (download + upload) / (1024 * 1024);
            final username = user['username']?.toString() ?? 'غير محدد';
            final isDisabled = user['disabled'] == 'true';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDisabled ? Colors.white.withOpacity(0.5) : Colors.white,
                          ),
                        ),
                        if (isDisabled)
                          Text('معطل', style: TextStyle(fontSize: 11, color: Colors.redAccent.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${totalMB.toStringAsFixed(1)} MB',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

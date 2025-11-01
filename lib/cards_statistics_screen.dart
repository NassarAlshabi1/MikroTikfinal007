import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'mikrotik_connector.dart';

enum TimeRange { all, today, week, month }

class CardsStatisticsScreen extends StatefulWidget {
  const CardsStatisticsScreen({super.key});

  @override
  State<CardsStatisticsScreen> createState() => _CardsStatisticsScreenState();
}

class _CardsStatisticsScreenState extends State<CardsStatisticsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _totalCards = 0;
  int _activeCards = 0;
  int _disabledCards = 0;
  int _cardsWithSessions = 0;
  int _totalSessions = 0;

  double _totalUploadGB = 0.0;
  double _totalDownloadGB = 0.0;
  Map<String, int> _cardsByProfile = {};

  TimeRange _selectedRange = TimeRange.all;
  List<Map<String, dynamic>> _usersRaw = [];
  List<Map<String, dynamic>> _sessionsRaw = [];

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final usersResponse = await client.talk([
        '/tool/user-manager/user/print',
      ]);

      final sessionsResponse = await client.talk([
        '/tool/user-manager/session/print',
      ]);

      _usersRaw = usersResponse.map((e) => Map<String, dynamic>.from(e)).toList();
      _sessionsRaw = sessionsResponse.map((e) => Map<String, dynamic>.from(e)).toList();

      _totalCards = _usersRaw.length;
      _activeCards = 0;
      _disabledCards = 0;
      _cardsByProfile.clear();

      double allTimeUploadBytes = 0.0;
      double allTimeDownloadBytes = 0.0;

      for (final user in _usersRaw) {
        final disabled = user['disabled'] == 'true';
        if (disabled) {
          _disabledCards++;
        } else {
          _activeCards++;
        }

        final uploadUsed = double.tryParse(user['upload-used'] ?? '0') ?? 0.0;
        final downloadUsed = double.tryParse(user['download-used'] ?? '0') ?? 0.0;
        allTimeUploadBytes += uploadUsed;
        allTimeDownloadBytes += downloadUsed;

        final profile = user['actual-profile'] ?? 'غير محدد';
        _cardsByProfile[profile] = (_cardsByProfile[profile] ?? 0) + 1;
      }

      _recalculateForRange(allTimeUploadBytes, allTimeDownloadBytes);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل تحميل الإحصائيات: ${e.toString()}';
        });
      }
    } finally {
      client?.close();
    }
  }

  void _recalculateForRange(double allTimeUploadBytes, double allTimeDownloadBytes) {
    final DateTime now = DateTime.now();
    DateTime? start;
    switch (_selectedRange) {
      case TimeRange.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimeRange.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        start = now.subtract(const Duration(days: 30));
        break;
      case TimeRange.all:
        start = null;
        break;
    }

    List<Map<String, dynamic>> filteredSessions;
    if (start == null) {
      filteredSessions = _sessionsRaw;
    } else {
      filteredSessions = _sessionsRaw.where((s) {
        final DateTime? st = _inferSessionStartTime(s);
        if (st == null) return false;
        return st.isAfter(start!);
      }).toList();
    }

    final Set<String> usersWithSessions = {};
    double periodUploadBytes = 0.0;
    double periodDownloadBytes = 0.0;

    for (final s in filteredSessions) {
      final u = s['user'];
      if (u != null) usersWithSessions.add(u);
      final su = double.tryParse(s['upload'] ?? '0') ?? 0.0;
      final sd = double.tryParse(s['download'] ?? '0') ?? 0.0;
      periodUploadBytes += su;
      periodDownloadBytes += sd;
    }

    _cardsWithSessions = usersWithSessions.length;
    _totalSessions = filteredSessions.length;

    if (_selectedRange == TimeRange.all) {
      _totalUploadGB = allTimeUploadBytes / (1024 * 1024 * 1024);
      _totalDownloadGB = allTimeDownloadBytes / (1024 * 1024 * 1024);
    } else {
      _totalUploadGB = periodUploadBytes / (1024 * 1024 * 1024);
      _totalDownloadGB = periodDownloadBytes / (1024 * 1024 * 1024);
    }
  }

  DateTime? _inferSessionStartTime(Map<String, dynamic> session) {
    final uptimeStr = session['uptime'];
    if (uptimeStr is String && uptimeStr.isNotEmpty) {
      final d = _parseRosDuration(uptimeStr);
      return DateTime.now().subtract(d);
    }
    final st = session['start-time'];
    if (st is String && st.isNotEmpty) {
      try {
        return DateTime.parse(st);
      } catch (_) {}
    }
    return null;
  }

  Duration _parseRosDuration(String s) {
    int weeks = 0, days = 0, hours = 0, minutes = 0, seconds = 0;
    String num = '';
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (RegExp(r'\d').hasMatch(ch)) {
        num += ch;
      } else {
        final v = int.tryParse(num) ?? 0;
        switch (ch) {
          case 'w':
            weeks = v;
            break;
          case 'd':
            days = v;
            break;
          case 'h':
            hours = v;
            break;
          case 'm':
            minutes = v;
            break;
          case 's':
            seconds = v;
            break;
        }
        num = '';
      }
    }
    return Duration(days: (weeks * 7) + days, hours: hours, minutes: minutes, seconds: seconds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات الكروت'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStatistics,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          onPressed: _fetchStatistics,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchStatistics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRangeSelector(theme),
                        const SizedBox(height: 12),
                        _buildSummaryCard(theme),
                        const SizedBox(height: 16),
                        _buildStatusGrid(theme),
                        const SizedBox(height: 16),
                        _buildUsageCard(theme),
                        const SizedBox(height: 16),
                        _buildProfilesCard(theme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildRangeSelector(ThemeData theme) {
    String label(TimeRange r) {
      switch (r) {
        case TimeRange.today:
          return 'اليوم';
        case TimeRange.week:
          return 'الأسبوع';
        case TimeRange.month:
          return 'الشهر';
        case TimeRange.all:
          return 'الكل';
      }
    }

    final items = TimeRange.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((r) {
        final selected = _selectedRange == r;
        return ChoiceChip(
          label: Text(label(r)),
          selected: selected,
          onSelected: (v) {
            if (!v || r == _selectedRange) return;
            setState(() {
              _selectedRange = r;
              double up = 0.0, down = 0.0;
              for (final u in _usersRaw) {
                up += double.tryParse(u['upload-used'] ?? '0') ?? 0.0;
                down += double.tryParse(u['download-used'] ?? '0') ?? 0.0;
              }
              _recalculateForRange(up, down);
            });
          },
          backgroundColor: theme.cardColor,
          selectedColor: theme.primaryColor.withOpacity(0.25),
          labelStyle: TextStyle(color: selected ? Colors.white : theme.textTheme.bodyMedium?.color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.credit_card, size: 64, color: theme.primaryColor),
            const SizedBox(height: 16),
            Text(
              '$_totalCards',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'إجمالي الكروت',
              style: TextStyle(
                fontSize: 18,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusGrid(ThemeData theme) {
    final stats = [
      {
        'title': 'الكروت المفعلة',
        'value': _activeCards,
        'icon': Icons.check_circle,
        'color': const Color(0xFF4CAF50),
      },
      {
        'title': 'الكروت المعطلة',
        'value': _disabledCards,
        'icon': Icons.cancel,
        'color': const Color(0xFFF44336),
      },
      {
        'title': 'النشطة حالياً',
        'value': _cardsWithSessions,
        'icon': Icons.wifi,
        'color': const Color(0xFF2196F3),
      },
      {
        'title': 'إجمالي الجلسات',
        'value': _totalSessions,
        'icon': Icons.devices,
        'color': const Color(0xFFFF9800),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  size: 36,
                  color: stat['color'] as Color,
                ),
                const SizedBox(height: 12),
                Text(
                  '${stat['value']}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsageCard(ThemeData theme) {
    String suffix;
    switch (_selectedRange) {
      case TimeRange.today:
        suffix = ' (اليوم)';
        break;
      case TimeRange.week:
        suffix = ' (آخر 7 أيام)';
        break;
      case TimeRange.month:
        suffix = ' (آخر 30 يوم)';
        break;
      case TimeRange.all:
        suffix = '';
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_usage, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'الاستخدام الكلي$suffix',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildUsageRow(
              'إجمالي التحميل',
              '${_totalDownloadGB.toStringAsFixed(2)} GB',
              Icons.download,
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 16),
            _buildUsageRow(
              'إجمالي الرفع',
              '${_totalUploadGB.toStringAsFixed(2)} GB',
              Icons.upload,
              const Color(0xFF2196F3),
            ),
            const SizedBox(height: 16),
            _buildUsageRow(
              'المجموع',
              '${(_totalDownloadGB + _totalUploadGB).toStringAsFixed(2)} GB',
              Icons.storage,
              const Color(0xFFFF9800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProfilesCard(ThemeData theme) {
    if (_cardsByProfile.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: theme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'الكروت حسب الفئة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._cardsByProfile.entries.map((entry) {
              final percentage = (_totalCards > 0
                  ? (entry.value / _totalCards * 100)
                  : 0.0).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 14)),
                        Text(
                          '${entry.value} ($percentage%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _totalCards > 0 ? entry.value / _totalCards : 0,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: theme.primaryColor,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

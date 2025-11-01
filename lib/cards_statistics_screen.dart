// lib/cards_statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'mikrotik_connector.dart';

class CardsStatisticsScreen extends StatefulWidget {
  const CardsStatisticsScreen({super.key});

  @override
  State<CardsStatisticsScreen> createState() => _CardsStatisticsScreenState();
}

class _CardsStatisticsScreenState extends State<CardsStatisticsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  // الإحصائيات
  int _totalCards = 0;
  int _activeCards = 0;        // الكروت المفعلة (disabled=false)
  int _disabledCards = 0;      // الكروت المعطلة (disabled=true)
  int _cardsWithSessions = 0;  // الكروت النشطة حالياً (لها جلسات)
  int _totalSessions = 0;      // إجمالي الجلسات النشطة
  
  // إحصائيات إضافية
  double _totalUploadGB = 0.0;
  double _totalDownloadGB = 0.0;
  Map<String, int> _cardsByProfile = {};  // عدد الكروت لكل Profile

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
      
      // جلب جميع المستخدمين (الكروت)
      final usersResponse = await client.talk([
        '/tool/user-manager/user/print',
      ]);
      
      _totalCards = usersResponse.length;
      _activeCards = 0;
      _disabledCards = 0;
      _totalUploadGB = 0.0;
      _totalDownloadGB = 0.0;
      _cardsByProfile.clear();
      
      // تحليل بيانات المستخدمين
      for (final user in usersResponse) {
        final disabled = user['disabled'] == 'true';
        if (disabled) {
          _disabledCards++;
        } else {
          _activeCards++;
        }
        
        // حساب الاستخدام الكلي
        final uploadUsed = int.tryParse(user['upload-used'] ?? '0') ?? 0;
        final downloadUsed = int.tryParse(user['download-used'] ?? '0') ?? 0;
        _totalUploadGB += uploadUsed / (1024 * 1024 * 1024);
        _totalDownloadGB += downloadUsed / (1024 * 1024 * 1024);
        
        // تصنيف حسب البروفايل
        final profile = user['actual-profile'] ?? 'غير محدد';
        _cardsByProfile[profile] = (_cardsByProfile[profile] ?? 0) + 1;
      }
      
      // جلب الجلسات النشطة
      final sessionsResponse = await client.talk([
        '/tool/user-manager/session/print',
      ]);
      
      _totalSessions = sessionsResponse.length;
      
      // حساب عدد الكروت التي لها جلسات نشطة
      final Set<String> usersWithSessions = {};
      for (final session in sessionsResponse) {
        final username = session['user'];
        if (username != null) {
          usersWithSessions.add(username);
        }
      }
      _cardsWithSessions = usersWithSessions.length;
      
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
                const Text(
                  'الاستخدام الكلي',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

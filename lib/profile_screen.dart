import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'perf/device_capability.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLinked = false;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final isLinked = prefs.getBool('is_network_linked') ?? false;

    if (isLinked) {
      final dataString = prefs.getString('qahtani_linked_data');
      if (dataString != null) {
        setState(() {
          _profileData = jsonDecode(dataString);
          _isLinked = true;
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي للشبكة'),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isLinked
              ? _buildProfileView()
              : _buildNotLinkedView(),
    );
  }

  Widget _buildProfileView() {
    final clientInfo = _profileData['client_info'] ?? {};
    final networkDetails = _profileData['network_details'] ?? {};

    // Pre-extract cheap data values; widgets are built lazily by ListView.builder
    final cards = <_ProfileCardData>[
      _ProfileCardData(
        title: clientInfo['name']?.toString() ?? 'غير متوفر',
        subtitle: 'اسم العميل',
        icon: Icons.person_outline,
      ),
      _ProfileCardData(
        title: clientInfo['phone']?.toString() ?? 'غير متوفر',
        subtitle: 'رقم هاتف العميل',
        icon: Icons.phone_outlined,
      ),
      _ProfileCardData(
        title: _profileData['account_id']?.toString() ?? 'غير متوفر',
        subtitle: 'رقم حساب م/نصار الشعبي',
        icon: Icons.confirmation_number_outlined,
      ),
      _ProfileCardData(
        title: networkDetails['network_name']?.toString() ?? 'غير متوفر',
        subtitle: 'اسم الشبكة المرتبطة',
        icon: Icons.wifi_outlined,
      ),
      _ProfileCardData(
        title: networkDetails['network_id']?.toString() ?? 'غير متوفر',
        subtitle: 'معرّف الشبكة (Network ID)',
        icon: Icons.hub_outlined,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        // 2 header items (Icon + gap) + N cards
        itemCount: cards.length + 2,
        cacheExtent: DeviceCapability.instance.listViewCacheExtent,
        addAutomaticKeepAlives: false,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Icon(Icons.account_circle, size: 100, color: Colors.deepOrange);
          }
          if (index == 1) {
            return const SizedBox(height: 16);
          }
          final c = cards[index - 2];
          return _buildInfoCard(
            context,
            title: c.title,
            subtitle: c.subtitle,
            icon: c.icon,
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String subtitle, required IconData icon}) {
    return RepaintBoundary(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildNotLinkedView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: Colors.amber),
            SizedBox(height: 20),
            Text(
              'لم يتم ربط الشبكة!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'الرجاء الذهاب إلى شاشة "ربط الشبكة بـ م/نصار الشعبي" لإكمال عملية الربط أولاً.',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper data class for lazy profile card rendering.
class _ProfileCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  const _ProfileCardData({required this.title, required this.subtitle, required this.icon});
}
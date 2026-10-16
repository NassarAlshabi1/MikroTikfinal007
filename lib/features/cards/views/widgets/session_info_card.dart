import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';

class SessionInfoCard extends StatelessWidget {
  final String from;
  final String to;
  final String ip;
  final String mac;
  final String upload;
  final String download;

  const SessionInfoCard({
    super.key,
    required this.from,
    required this.to,
    required this.ip,
    required this.mac,
    required this.upload,
    required this.download,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // شريط الوقت العلوي في البطاقة
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_toggle_off_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  "$from  ←  $to",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _buildRow(Icons.lan_outlined, "العنوان (IP)", ip),
                _buildRow(Icons.fingerprint_rounded, "الماك (MAC)", mac),
                const Divider(height: 25, color: AppColors.soft),
                // عرض الرفع والتنزيل بجانب بعض
                Row(
                  children: [
                    Expanded(child: _buildTraffic(Icons.cloud_upload, "رفع", upload, Colors.orange)),
                    const SizedBox(width: 11),
                    Expanded(child: _buildTraffic(Icons.cloud_download, "تنزيل", download, Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.border),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTraffic(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CardItemTile extends StatelessWidget {
  final String username;
  final String package;
  final String status; // active, normal, expired
  final VoidCallback onTap;
  final VoidCallback onAnalyticsTap;

  const CardItemTile({
    super.key,
    required this.username,
    required this.package,
    required this.status,
    required this.onTap,
    required this.onAnalyticsTap,
  });

  @override
  Widget build(BuildContext context) {
    
    // تحديد اللون والأيقونة بناءً على الحالة
    Color statusColor;
    IconData statusIcon;

    if (status == "active") {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    } else if (status == "normal") {
      statusColor = const Color(0xFF0EA5E9); // لون أزرق للبطاقات الجديدة
      statusIcon = Icons.fiber_new_rounded;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.pause_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              // أيقونة الحالة الديناميكية
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 11),
              // معلومات الكرت
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 15, 
                        color: Color(0xFFE8EEF9)
                      ),
                    ),
                    Text(
                      "باقة: $package",
                      style: TextStyle(color: const Color(0xFF8FA3C0), fontSize: 11),
                    ),
                  ],
                ),
              ),
              // زر الانتقال لسجل الجلسات
              IconButton(
                icon: const Icon(Icons.analytics_outlined, color: Color(0xFF3B82F6), size: 22),
                onPressed: onAnalyticsTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
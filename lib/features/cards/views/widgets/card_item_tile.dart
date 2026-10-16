import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';

class CardItemTile extends StatelessWidget {
  final String username;
  final String package;
  final String status; // active, normal, expired
  final VoidCallback onTap;
  final VoidCallback onAnalyticsTap;

  /// وضع التحديد الجماعي (مثل ABOTALAL) — ضغطة مطوّلة تدخله وضغطة تبدّله.
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onLongPress;

  const CardItemTile({
    super.key,
    required this.username,
    required this.package,
    required this.status,
    required this.onTap,
    required this.onAnalyticsTap,
    this.selectionMode = false,
    this.selected = false,
    this.onLongPress,
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
      statusColor = AppColors.sky; // لون أزرق للبطاقات الجديدة
      statusIcon = Icons.fiber_new_rounded;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.pause_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.info.withValues(alpha: 0.12) : AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: selected
            ? Border.all(color: AppColors.info, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              // علامة التحديد أو أيقونة الحالة الديناميكية
              if (selectionMode)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.info
                        : statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : statusIcon,
                    color: selected ? Colors.white : statusColor,
                    size: 26,
                  ),
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
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
                        color: AppColors.text
                      ),
                    ),
                    Text(
                      "باقة: $package",
                      style: const TextStyle(color: AppColors.textSubtle, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // زر الانتقال لسجل الجلسات (يخفي أثناء وضع التحديد)
              if (!selectionMode)
                IconButton(
                  icon: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 22),
                  onPressed: onAnalyticsTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

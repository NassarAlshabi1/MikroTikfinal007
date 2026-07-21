// ============================================================
//  MetricsCard — widget reusable لعرض رقم + أيقونة + label
//
//  مستوحى من smartconnect-app/lib/metrics_card.dart
//  تصميم حديث أنيق مع LayoutBuilder للـ responsive
// ============================================================

import 'package:flutter/material.dart';

/// بطاقة لعرض مقياس واحد (رقم + أيقونة + label)
///
/// مثال:
/// ```dart
/// MetricsCard(
///   icon: Icons.people,
///   label: 'مستخدمين نشطين',
///   count: 42,
///   color: Colors.green,
/// )
/// ```
class MetricsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const MetricsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    this.color = Colors.indigo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 160;
        final iconSize = isSmallScreen ? 20.0 : 28.0;
        final titleSize = isSmallScreen ? 20.0 : 28.0;
        final labelSize = isSmallScreen ? 10.0 : 12.0;
        final padding = isSmallScreen ? 8.0 : 16.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: iconSize, color: color),
                ),
                SizedBox(height: isSmallScreen ? 6 : 10),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelSize,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';

/// بطاقة إحصائية صغيرة في أعلى الداشبورد (قيمة + عنوان + أيقونة ملوّنة).
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBright)),
            ),
            const SizedBox(height: 2),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// بانر الإجراء الرئيسي (توليد كرت) بخلفية متدرّجة.
class PrimaryActionBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const PrimaryActionBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.blue, AppColors.cyanDark],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xCCFFFFFF), fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

/// بطاقة "أداء النظام" بثلاثة أشرطة تقدّم (CPU / RAM / Disk).
class ResourcePanel extends StatelessWidget {
  final String cpu;
  final String ram;
  final String disk;
  final String diskDetails;
  final VoidCallback? onTap;

  const ResourcePanel({
    super.key,
    required this.cpu,
    required this.ram,
    required this.disk,
    required this.diskDetails,
    this.onTap,
  });

  static double _toFraction(String percent) =>
      (double.tryParse(percent.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0)
          .clamp(0, 100) /
      100;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderBlue.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.speed_rounded,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                const Text("أداء النظام",
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPale)),
                const Spacer(),
                Flexible(
                  child: Text(diskDetails,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _bar("المعالج", cpu, AppColors.cyan),
            const SizedBox(height: 8),
            _bar("الرام", ram, AppColors.violet),
            const SizedBox(height: 8),
            _bar("القرص", disk, AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _bar(String label, String value, Color color) {
    final fraction = _toFraction(value);
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: AppColors.overlay,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 38,
          child: Text(value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textBright)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final List<Color> colors;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    this.onPressed,
    this.icon,
    this.label = 'تأكيد', // قيمة افتراضية للنص
    this.colors = const [Color(0xff1E3C72), Color(0xff2563EB)], // الألوان الافتراضية المطلوبة
    this.width,
    this.height = 45.0, // ارتفاع افتراضي
  });

  @override
  Widget build(BuildContext context) {
    // فصلنا الستايل هنا عشان ما نكرر الكود
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );

    const textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: icon != null
          // إذا تم تمرير أيقونة، نعرض الزر مع الأيقونة
          ? ElevatedButton.icon(
              onPressed: onPressed ?? () {}, // إذا كان null نعطيه دالة فارغة
              icon: Icon(icon, size: 18),
              label: Text(label, style: textStyle),
              style: buttonStyle,
            )
          // إذا لم يتم تمرير أيقونة، نعرض زر نصي فقط
          : ElevatedButton(
              onPressed: onPressed ?? () {},
              style: buttonStyle,
              child: Text(label, style: textStyle),
            ),
    );
  }
}
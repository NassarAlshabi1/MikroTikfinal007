import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PremiumHeader extends StatelessWidget {
  final String title;          // العنوان الأساسي (مثلاً: إدارة الكروت)
  final String? subtitle;       // عنوان فرعي صغير (اختياري)
  final IconData? icon;        // أيقونة تظهر على اليسار (اختياري)
  final bool showBackButton;   // هل يظهر سهم الرجوع؟ (افتراضياً نعم)
  final VoidCallback? goBack;

  const PremiumHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.showBackButton = true,
    this.goBack 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        // التدرج اللوني الذي تفضله (Dark Blue Gradient)
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // زر الرجوع يظهر فقط إذا كانت showBackButton = true
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, 
                            color: Colors.white, size: 22),
                      onPressed: goBack ?? Get.back,
                    )
                  else
                    const SizedBox(width: 48), // مساحة فارغة للحفاظ على التوازن

                  // العنوان الرئيسي
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      //fontFamily: 'Cairo', // تأكد من إضافة الخط في pubspec
                    ),
                  ),

                  // أيقونة مخصصة تظهر على اليسار
                  icon != null 
                    ? Icon(icon, color: Colors.white.withOpacity(0.5), size: 28)
                    : const SizedBox(width: 48),
                ],
              ),
              
              // العنوان الفرعي يظهر فقط إذا قمت بتمريره
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8), 
                      fontSize: 11,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

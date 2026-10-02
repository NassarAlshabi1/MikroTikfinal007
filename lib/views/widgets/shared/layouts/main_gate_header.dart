import 'package:flutter/material.dart';

class MainGateHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool showButton;

  const MainGateHeader({
    super.key,
    required this.title,
    required this.subtitle,
     this.icon,
    this.showButton=true
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: 200,
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xff0F172A), 
            Color(0xff1E3C72), 
            Color(0xff2563EB)
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x441E3C72),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          // تأثير الدائرة الجمالية الخلفية
          Positioned(
            top: -20,
            left: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // الأيقونة المركزية داخل دائرة بيضاء
                if(icon !=null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child:icon != null ? Icon(icon, color: const Color(0xff1E3C72), size: 35):null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // زر الخروج (الرجوع) الموجه لليمين
          Visibility(
            visible: showButton,
            child: Positioned(
              top: 45,
              right: 20,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  // تم تعديل الأيقونة هنا لتشير لليمين في نظام RTL
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded, 
                    color: Colors.white, 
                    size: 18
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

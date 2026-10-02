import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/controllers/login_controller.dart';

// استيراد المكونات المشتركة للتصميم الجديد
import '/views/widgets/shared/layouts/main_gate_header.dart';
import '/views/widgets/shared/layouts/app_mini_footer.dart';
import '/views/widgets/shared/typography/section_title.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), 
        body: Column(
          children: [
            // 1. الهيدر
            const MainGateHeader(
              title: "تسجيل الدخول إلى الميكروتك",
              subtitle: "الرجاء إدخال بيانات الراوتر للمتابعة",
              icon: Icons.lock_outline_rounded,
              showButton: false,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SectionTitle(title: "بيانات تسجيل الدخول"),
                  
                  // 2. الكرت الأبيض الذي يحتوي على الحقول
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // الحقل الأول: الـ Host والـ Port في نفس السطر
                        Row(
                          children: [
                            Expanded(
                              flex: 2, // يأخذ ثلثي المساحة
                              child: _buildInputField(
                                label: "عنوان IP السيرفر",
                                icon: Icons.lan_outlined,
                                ctrl: controller.hostController,
                              ),
                            ),
                            const SizedBox(width: 10), // مسافة بين الحقلين
                            Expanded(
                              flex: 1, // يأخذ ثلث المساحة
                              child: _buildInputField(
                                label: "المنفذ",
                                icon: Icons.numbers_rounded,
                                ctrl: controller.portController,
                              ),
                            ),
                          ],
                        ),
                        
                        // الحقل الثاني: اسم المستخدم
                        _buildInputField(
                          label: "اسم المستخدم",
                          icon: Icons.person,
                          ctrl: controller.userController,
                        ),
                        
                        // الحقل الثالث: كلمة المرور
                        _buildInputField(
                          label: "كلمة المرور",
                          icon: Icons.lock,
                          ctrl: controller.passwordController,
                          isPassword: true,
                        ),
                        
                        // الحقل الرابع والأخير: اسم الشبكة
                        _buildInputField(
                          label: "اسم الشبكة المحلية",
                          icon: Icons.language, 
                          ctrl: controller.nameController,
                          isLast: true, // لإزالة المسافة السفلية
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 3. أزرار الإجراءات
                  _buildActionBtn(
                    text: "تسجيل الدخول",
                    icon: Icons.login_rounded,
                    bgColor: const Color(0xFF2563EB), 
                    textColor: Colors.white,
                    onPressed: controller.connectToRouter,
                  ),
                  
                  _buildActionBtn(
                    text: "حفظ البيانات",
                    icon: Icons.save_rounded,
                    bgColor: const Color(0xFF3B82F6), 
                    textColor: Colors.white,
                    onPressed: controller.addRouterData,
                  ),

                  _buildActionBtn(
                    text: "البيانات المحفوظة",
                    icon: Icons.manage_search_rounded,
                    bgColor: const Color(0xFFE2E8F0), 
                    textColor: const Color(0xFF475569), 
                    onPressed: controller.showSavedData,
                  ),
                ],
              ),
            ),

            // 4. الفوتر
             AppMiniFooter(
              title: Text("تسجيل الدخول إلى الميكروتك",
                style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey.shade400),),
              subTitle: Text("الرجاء إدخال بيانات الراوتر للمتابعة",style: TextStyle(color: Colors.blueGrey.shade200,fontSize: 12),),
              ),
          ],
        ),
      ),
    );
  }

  /* ================= تصميم حقل الإدخال الجديد ================= */
  /* ================= تصميم حقل الإدخال الجديد ================= */
  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    bool isPassword = false,
    bool isLast = false,
  }) {
    // 1. فصلنا تصميم الحقل في دالة داخلية عشان ما نكرر الكود
    Widget buildTextField(bool isObscured) {
      return TextField(
        controller: ctrl,
        obscureText: isObscured,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: 1.2),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelAlignment: FloatingLabelAlignment.center,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13, letterSpacing: 0),
          prefixIcon: Icon(icon, color: const Color(0xFF475569), size: 22), 
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    controller.hidePassword.value ? Icons.visibility_off : Icons.visibility, 
                    color: const Color(0xFF94A3B8), 
                    size: 20
                  ),
                  onPressed: () => controller.hidePassword.toggle(), 
                )
              : null,
          contentPadding: const EdgeInsets.only(top: 16,bottom: 16,right: 0,left: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
      // 2. هنا السحر: نستخدم Obx فقط إذا كان الحقل هو كلمة المرور!
      child: isPassword 
          ? Obx(() => buildTextField(controller.hidePassword.value))
          : buildTextField(false), // الحقول العادية ترسم بدون Obx
    );
  }

  /* ================= تصميم الأزرار السفلية الموحدة ================= */
  Widget _buildActionBtn({
    required String text,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}
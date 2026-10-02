import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/cards/profiles/edit_profile_controller.dart';
import '../../widgets/shared/layouts/app_mini_footer.dart';
import '../../widgets/shared/layouts/sub_page_header.dart';
import '../../widgets/shared/layouts/modern_input.dart';

class EditProfilePage extends GetView<EditProfileController> {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
             PremiumHeader(
              title: "تعديل باقة",
              subtitle: "تعديل بيانات باقة ${controller.profile.name}",
              icon: Icons.edit,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                   color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 15,
                        color: Colors.black.withOpacity(0.03),
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel("بيانات الباقة"),
                      const SizedBox(height: 10),
                      
                    Row(children: [
                      Expanded(
                        flex: 2,
                        child: ModernInput(
                        label:  "اسم الباقة", 
                        icon: Icons.badge_outlined, 
                        controller: controller.nameCtrl
                        ),
                      ),
                      const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: ModernInput(
                        label:  "السعر", 
                        icon: Icons.payments_outlined, 
                        controller: controller.priceCtrl,
                        isNumber: true,
                        )),
                    
                    ],),
                      _sectionLabel("تحديد الرصيد (Data Limit)"),
                     Row(children: [
                      Expanded(
                        child: ModernInput(
                          label:  "ميجا بايت (MB)", 
                          icon: Icons.sd_card_rounded, 
                          controller: controller.megasCtrl,
                          isNumber: true,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ModernInput(
                          label: "جيجا بايت (GB)", 
                          icon: Icons.storage_rounded, 
                          controller: controller.gigasCtrl,
                          isNumber: true,
                          ),
                        ),
                    ]),
                    

                    _sectionLabel("تحديد الصلاحية (بقاء الكرت)"),
                    Row(children: [
                    Expanded(
                        child: ModernInput(
                          label:   "أيام", 
                          icon: Icons.calendar_month, 
                          controller: controller.daysCtrl,
                          isNumber: true,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ModernInput(
                          label: "ساعات", 
                          icon: Icons.more_time, 
                          controller: controller.hoursCtrl,
                          isNumber: true,
                          ),
                        ),
                    ]),
                   

                    _sectionLabel("تحديد الوقت (Uptime)"),
                    Row(children: [
                    Expanded(
                        child: ModernInput(
                          label:   "أيام", 
                          icon: Icons.calendar_month, 
                          controller: controller.uptimeDaysCtrl,
                          isNumber: true,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ModernInput(
                          label: "ساعات", 
                          icon: Icons.more_time, 
                          controller: controller.uptimeHoursCtrl,
                          isNumber: true,
                          ),
                        ),
                    ]),
                    

                    _sectionLabel("تحديد السرعة"),
                    ModernInput(
                      label:   "مثال: 4M/4M", 
                      icon: Icons.speed, 
                      controller: controller.speedCtrl
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // زر الحفظ مع مراقبة حالة التحميل
                      _buildSaveButton()
                    ],
                  ),
                ),
              ),
            ),
            
           AppMiniFooter(
              title: Text("تعديل بيانات الباقة الحالية",
                style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey.shade400),),
              ),
          ],
        ),
      ),
    );
  }
  

  

  Widget _buildSaveButton() {
    return InkWell(
      onTap: controller.executeEdit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient:const LinearGradient(
            colors: 

             [ Color(0xFF0F172A), Color(0xFF1E3A8A)]
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child:const Center(
          child:  Text(
                "حفظ التعديلات",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) => Container(
        alignment: Alignment.centerRight,
       // margin: const EdgeInsets.only(top: 20, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E3A8A))),
          ],
        ),
      );
 
  
}
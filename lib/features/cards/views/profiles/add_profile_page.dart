import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:mikronet/features/cards/controllers/profiles/add_profile_controller.dart';
import 'package:mikronet/core/ui/widgets/app_mini_footer.dart';
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:mikronet/core/ui/widgets/modern_input.dart';

class AddProfilePage extends GetView<AddProfileController> {
  const AddProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            const PremiumHeader(
              title: "إضافة باقة جديدة",
              subtitle: "إنشاء باقة جديدة وتحديد الوقت والصلاحية",
              icon: Icons.add_card_rounded,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 25),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                   color: AppColors.soft,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 15,
                        color: Colors.black.withValues(alpha: 0.03),
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
                      Obx(() => _buildSaveButton()),
                    ],
                  ),
                ),
              ),
            ),
            
           const AppMiniFooter(
              title: Text("إنشاء باقة جديدة وتحديد الوقت والصلاحية",
                style: TextStyle(fontWeight: FontWeight.bold,color: AppColors.textSubtle),),
              ),
          ],
        ),
      ),
    );
  }
  

  

  Widget _buildSaveButton() {
    return InkWell(
      onTap: controller.executeAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: controller.isLoading.value 
              ? [Colors.grey, AppColors.textMuted]
              : [AppColors.headerTop, AppColors.headerBottom]
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: controller.isLoading.value 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                "اضافة الباقة",
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary)),
          ],
        ),
      );
 
  
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:mikronet/controllers/print/batches_controller.dart';
import 'package:mikronet/controllers/prints/batches/batch_cards_controller.dart';
import 'package:mikronet/models/print_model.dart';

// استيراد الويجيت الموحدة
import '../../widgets/shared/layouts/sub_page_header.dart';
// import '../../widgets/shared/layouts/app_mini_footer.dart';
import '../../widgets/shared/typography/section_title.dart';



class GeneratedCardsView extends StatelessWidget {
  final List<GeneratedCardsModel> generatedCards;
  const GeneratedCardsView(this.generatedCards,{super.key,});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: GetBuilder<GeneratedCardsController>(
          init: GeneratedCardsController(generatedCards),
          builder: (controller) {
            return Column(
              children: [
                const PremiumHeader(
                  title: "الكروت المولدة",
                  subtitle: "إدارة وإرسال الكروت إلى السيرفر",
                  icon: Icons.auto_awesome_motion_rounded,
                ),
            
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: "لوحة التحكم والإحصائيات"),
                        const SizedBox(height: 12),
                        
                        // 1. إضافة لوحة التحكم (الإحصائيات والأزرار)
                        _buildControlPanel(controller),
                        
                        const SizedBox(height: 25),
                        const SectionTitle(title: "تفاصيل الكروت"),
                        const SizedBox(height: 12),
                        
                        // 2. الجدول الخاص بالكروت
                        _buildTableCard(controller),
                      ],
                    ),
                  ),
                ),
            
                //const AppMiniFooter(title: Text("Micronet Card Engine")),
              ],
            );
          }
        ),
      ),
    );
  }

  // --- ويدجت لوحة التحكم الجديدة ---
  // --- ويدجت لوحة التحكم المُحدثة ---
  Widget _buildControlPanel(GeneratedCardsController controller) {
    int addedCount = controller.generatedCards.where((c) => c.isAdd == true).length;
    int remainingCount = (controller.generatedCards.length) - addedCount;

    // تمكين الأزرار يعتمد على حالة التحميل وحالة الرفع
    bool canStart = !controller.isUploading && remainingCount > 0 && !controller.isLoading;
    bool canStop = controller.isUploading;

    return Column(
      children: [
        // صف الإحصائيات
        Row(
          children: [
            _buildStatItem("الكروت المضافة", addedCount.toString(), Colors.green, Icons.cloud_done_rounded),
            const SizedBox(width: 12),
            _buildStatItem("كروت متبقية", remainingCount.toString(), Colors.orange, Icons.hourglass_empty_rounded),
          ],
        ),
        const SizedBox(height: 15),
        
        // صف أزرار التحكم
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                controller.isLoading 
                  ? "جاري المزامنة..." 
                  : (controller.isUploading ? "جاري الإرسال..." : "بدء الإضافة للسيرفر"), 
                canStart ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)] : [Colors.grey.shade400, Colors.grey.shade600], 
                controller.isUploading || controller.isLoading ? Icons.sync : Icons.cloud_upload_rounded, 
                () {
                  if(canStart) _handleStartUpload(controller);
                }
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionBtn(
                "إيقاف العملية", 
                canStop ? [const Color(0xFFEF4444), const Color(0xFF991B1B)] : [Colors.grey.shade400, Colors.grey.shade600], 
                Icons.stop_circle_rounded, 
                () {
                  if(canStop) _handleStopUpload(controller);
                }
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- تحديث قسم الجدول ليُظهر حالة التحميل (Loading) إذا لزم الأمر ---
  Widget _buildTableCard(GeneratedCardsController controller) {
    final cardsList = controller.generatedCards ; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: controller.isLoading 
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          : cardsList.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 13),
                    dataTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 13),
                    columnSpacing: 25,
                    horizontalMargin: 15,
                    columns: const [
                      DataColumn(label: Text("اسم المستخدم")),
                      DataColumn(label: Text("كلمة المرور")),
                      DataColumn(label: Text("الباقة (Profile)")),
                      DataColumn(label: Text("الحالة")),
                    ],
                    rows: cardsList.map<DataRow>((card) {
                      return DataRow(
                        cells: [
                          DataCell(Text(card.username.toString())),
                          DataCell(Text(card.password.toString())),
                          DataCell(_buildProfileBadge(card.profileName.toString())),
                          DataCell(_buildStatusBadge(card.isAdd)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }

  // ويدجت صغير لعرض إحصائية واحدة
  Widget _buildStatItem(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 18,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ويدجت الزر (بنفس ستايل صفحة الإضافة)
  Widget _buildActionBtn(String text, List<Color> colors, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // --- الدوال الوظيفية ---
  void _handleStartUpload(GeneratedCardsController controller) {
    // هنا تضع كود البدء
    Get.snackbar("بدء العملية", "جاري إرسال الكروت إلى السيرفر...", snackPosition: SnackPosition.BOTTOM);
    controller.startUploadingToServer();
  }

  void _handleStopUpload(GeneratedCardsController controller) {
    // هنا تضع كود الإيقاف
    controller.stopUploading();
    Get.snackbar("تنبيه", "تم إيقاف عملية الإرسال", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
  }

  // (ويدجت الجدول المذكور في الرد السابق يبقى كما هو)
  Widget _buildTableCard1(GeneratedCardsController controller) {
    // نفترض أن الكروت موجودة في قائمة داخل الكنترولر بهذا الشكل:
    // List<Map<String, dynamic>> generatedCards = [{'username': '..', 'password': '..', 'profile': '..', 'isAdded': true/false}]
    // يمكنك تعديل controller.generatedCards بناءً على اسم المتغير الفعلي لديك
    // final cardsList = controller.generatedCards ?? []; 
    final cardsList = controller.generatedCards ; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: cardsList.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                  fontSize: 13,
                ),
                dataTextStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  fontSize: 13,
                ),
                columnSpacing: 25,
                horizontalMargin: 15,
                columns: const [
                  DataColumn(label: Text("اسم المستخدم")),
                  DataColumn(label: Text("كلمة المرور")),
                  DataColumn(label: Text("الباقة (Profile)")),
                  DataColumn(label: Text("الحالة")),
                ],
                rows: cardsList.map<DataRow>((card) {
                  return DataRow(
                    cells: [
                      DataCell(Text(card.username.toString())),
                      DataCell(Text(card.password.toString())),
                      DataCell(_buildProfileBadge(card.profileName.toString())),
                      DataCell(_buildStatusBadge(card.isAdd)),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  // ويدجت لتصميم شارة الباقة
  Widget _buildProfileBadge(String profileName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        profileName,
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ويدجت لتصميم حالة الكرت (مضاف / غير مضاف)
  Widget _buildStatusBadge(bool isAdded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAdded ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdded ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            color: isAdded ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isAdded ? "تمت الإضافة" : "قيد الإنتظار",
            style: TextStyle(
              color: isAdded ? Colors.green : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // واجهة في حال عدم وجود كروت
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.layers_clear_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          const Text(
            "لا توجد كروت مولدة حتى الآن",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }



}



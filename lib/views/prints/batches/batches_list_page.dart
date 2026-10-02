import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/prints/batches/add_batch_controller.dart';
import 'package:mikronet/models/print_model.dart';
import '../../../controllers/prints/batches/batches_list_controller.dart';
import 'add_batch_page.dart';

class BatchesView extends GetView<BatchesListController> {
  BatchesView({super.key});
  final TextEditingController searchCtrl = TextEditingController();
  final RxString searchQuery = "".obs;
  final RxString filterType = "ALL".obs;

  @override
  Widget build(BuildContext context) {
    // التأكد من تهيئة الكنترولر (في حال لم يتم تهيئته في الـ Binding)
    Get.put(BatchesListController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF1E3A8A),
          onPressed: () {
            Get.to(() => AddBatchView(controller: BatchesFormController()))?.then((_) {
             controller.update(); // لتحديث القائمة بعد العودة من الإضافة
               });
          },
          label: const Text("إضافة دفعة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        ),
        body: Column(
          children: [
            _buildBalancedHeader(),
            
            // استخدام GetBuilder للبيانات + Obx للفلترة والبحث
            Expanded(
              child: GetBuilder<BatchesListController>(
                builder: (ctrl) {
                  if (ctrl.isLoading) { // افتراض وجود isLoading في الكنترولر الفعلي
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return Obx(() {
                    // 1. جلب البيانات الأساسية
                    List<PrintBatchesModel> filteredBatches = ctrl.allBatches;

                    // 2. تطبيق البحث
                    if (searchQuery.value.isNotEmpty) {
                      filteredBatches = filteredBatches
                          .where((b) => b.cardsProfile.toLowerCase().contains(searchQuery.value.toLowerCase()))
                          .toList();
                    }

                    // 3. تطبيق الفلترة
                    filteredBatches = filteredBatches.where((b) {
                      const sold = 1; // القيم الافتراضية من كودك
                      const remaining = 0; 
                      
                      if (filterType.value == "FULL") return sold == 0;
                      if (filterType.value == "USING") return remaining > 0 && sold > 0;
                      if (filterType.value == "ENDED") return remaining == 0;
                      return true;
                    }).toList();

                    return Column(
                      children: [
                        _buildSmallStats(ctrl.allBatches.length),
                        _buildSearchRow(),
                        //_buildFilterTabs(),
                        Expanded(child: _buildBatchesList(filteredBatches)),
                      ],
                    );
                  });
                },
              ),
            ),
            //_buildFooter(),
          ],
        ),
      ),
    );
  }

  /* ================= الهيدر ================= */
  Widget _buildBalancedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
            const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 35),
            const SizedBox(height: 8),
            const Text(
              "دفعات الكروت والاستهلاك",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= العداد العلوي ================= */
  Widget _buildSmallStats(int count) {
    return Transform.translate(
      offset: const Offset(0, -15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Text(
          "إجمالي الدفعات: $count",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)),
        ),
      ),
    );
  }

  /* ================= البحث والإضافة ================= */
  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: (val) => searchQuery.value = val, // تحديث البحث تفاعلياً
                decoration: const InputDecoration(
                  hintText: "بحث عن دفعة...",
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF1E3A8A)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // const SizedBox(width: 10),
          
          // InkWell(
          //   onTap: () {
          //     Get.to(() => AddBatchView(controller: BatchesFormController()))?.then((_) {
          //       controller.update(); // لتحديث القائمة بعد العودة من الإضافة
          //     });
          //   },
          //   child: Container(
          //     padding: const EdgeInsets.all(12),
          //     decoration: BoxDecoration(
          //       color: const Color(0xFF1E3A8A),
          //       borderRadius: BorderRadius.circular(15),
          //     ),
          //     child: const Icon(Icons.add_rounded, color: Colors.white),
          //   ),
          // ),
        ],
      ),
    );
  }

  /* ================= الفلاتر ================= */
  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        children: [
          _filterItem("ALL", "الكل"),
          _filterItem("FULL", "ممتلئة"),
          _filterItem("USING", "قيد الاستهلاك"),
          _filterItem("ENDED", "منتهية"),
        ],
      ),
    );
  }

  Widget _filterItem(String key, String title) {
    return Obx(() {
      final active = filterType.value == key;
      return GestureDetector(
        onTap: () => filterType.value = key, // تحديث الفلتر تفاعلياً
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? Colors.transparent : const Color(0xFFE2E8F0)),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: active ? Colors.white : Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    });
  }

  /* ================= قائمة الدفعات ================= */
  Widget _buildBatchesList(List<PrintBatchesModel> batches) {
    if (batches.isEmpty) return const Center(child: Text("لا توجد دفعات حالياً"));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 20),
      itemCount: batches.length,
      itemBuilder: (_, i) {
        final b = batches[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                subtitle: Text("الانشاء : ${b.createdAt.toString().split(" ").first} ", style: const TextStyle(fontSize: 11)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                        onPressed: () {
                          _showEditBatchDialog(Get.context!, b);
                        }),
                    IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                        onPressed: () {
                          _showDeleteBatchDialog(b);
                        }),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    _buildStatMini(Icons.confirmation_number_outlined, "عدد الكروت", b.generatedCards.length),
                    _buildStatMini(Icons.sell_outlined, "الباقة", b.cardsProfile),
                    _buildStatMini(Icons.login_rounded, "البادئة", b.cardPrefix),
                    _buildStatMini(Icons.logout_rounded, "اللاحقة", b.cardSuffix),
                  ],
                ),
              ),
              _buildPrintAction(
                b.toDatabase(),
                onTap: () {
                  controller.getBatchPreview(b.id);
                },
              ),
              const Divider(height: 5),
              _buildPrintAction(
                b.toDatabase(),
                text: "عرض الكروت",
                textColor: Colors.orange,
                btnIcon: const Icon(Icons.view_agenda_outlined, size: 18, color: Colors.orange),
                onTap: () {
                  controller.getBatchCards(b.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /* ================= نافذة خيارات الحذف (محدثة لـ GetX) ================= */
  void _showDeleteBatchDialog(PrintBatchesModel batch) {
    RxInt selectedOption = 2.obs; // تحويله لمتغير تفاعلي بدلاً من StatefulBuilder

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text("تأكيد الحذف", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Obx(() => Column( // استخدام Obx هنا لتحديث الخيارات فورا
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "هل أنت متأكد من رغبتك في حذف الدفعة '${batch.name}'؟\nالرجاء تحديد نطاق الحذف المناسب:",
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  _buildDeleteOptionCard(
                    title: "من السيرفر (المايكروتك) فقط",
                    value: 1,
                    groupValue: selectedOption.value,
                    onChanged: (val) => selectedOption.value = val!,
                  ),
                  _buildDeleteOptionCard(
                    title: "من قاعدة البيانات (التطبيق) فقط",
                    value: 2,
                    groupValue: selectedOption.value,
                    onChanged: (val) => selectedOption.value = val!,
                  ),
                  _buildDeleteOptionCard(
                    title: "من السيرفر وقاعدة البيانات معاً",
                    value: 3,
                    groupValue: selectedOption.value,
                    isDestructive: true,
                    onChanged: (val) => selectedOption.value = val!,
                  ),
                ],
              )),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            GetBuilder<BatchesListController>(
              builder: (ctrl) {
                if (ctrl.isDeleteLoading ?? false) {
                   return const CircularProgressIndicator();
                }
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // استدعاء دالة الحذف من الكنترولر وتمرير الخيار
                    await ctrl.deleteBatch(batch, selectedOption.value);
                    Get.back(); // إغلاق النافذة بعد الانتهاء
                  },
                  child: const Text("تأكيد الحذف", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  /* ================= تصميم خيار الحذف ================= */
  Widget _buildDeleteOptionCard({
    required String title,
    required int value,
    required int groupValue,
    required ValueChanged<int?> onChanged,
    bool isDestructive = false,
  }) {
    bool isSelected = value == groupValue;
    Color activeColor = isDestructive ? Colors.redAccent : const Color(0xFF2563EB);
    Color bgColor = isSelected ? activeColor.withOpacity(0.08) : Colors.transparent;
    Color borderColor = isSelected ? activeColor : Colors.grey.withOpacity(0.3);

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? activeColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? activeColor : Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= نافذة تعديل بيانات الدفعة (محدثة لـ GetX) ================= */
  void _showEditBatchDialog(BuildContext context, PrintBatchesModel batch) {
    TextEditingController nameController = TextEditingController(text: batch.name);
    Rx<DateTime> selectedDate = batch.createdAt.obs; // تحويل التاريخ لتفاعلي

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_square, color: Color(0xFF1E3A8A)),
              SizedBox(width: 10),
              Text("تعديل بيانات الدفعة", style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "اسم الدفعة",
                      labelStyle: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                      prefixIcon: const Icon(Icons.title, color: Colors.blueGrey, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.value,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFF1E3A8A)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        selectedDate.value = picked; // التحديث التلقائي عبر Rx
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "تاريخ الإنشاء",
                        labelStyle: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                        prefixIcon: const Icon(Icons.calendar_month_rounded, color: Colors.blueGrey, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              )),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                await controller.editBatch(batch, nameController.text, selectedDate.value);
                Get.back();
              },
              child: const Text("حفظ التعديلات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMini(IconData icon, String label, dynamic val) {
    return SizedBox(
      width: 130,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text("$val", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrintAction(Map b, {
    String text = "معاينة وطباعة الدفعة",
    Color textColor = Colors.green,
    Icon btnIcon = const Icon(Icons.print_rounded, size: 18, color: Colors.green),
    void Function()? onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            btnIcon,
            const SizedBox(width: 10),
            Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  
}
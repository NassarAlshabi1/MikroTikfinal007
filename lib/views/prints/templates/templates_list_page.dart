// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/app_pages.dart';
import 'package:mikronet/views/widgets/shared/layouts/floating_button.dart';
import 'package:mikronet/views/widgets/shared/layouts/main_gate_header.dart';
import '../../../controllers/prints/templates/templates_list_controller.dart';
import '/models/print_model.dart';


// import '/views/helpers/dialogs.dart';
// import 'templates_form.dart';
// import '../print/page_preview.dart';

class TemplatesListPage extends GetView<TemplatesListController> {
  const TemplatesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        body: Column(
          children: [
            const MainGateHeader(title: "مكتبة القوالب المحفوظة", subtitle: "", icon: Icons.bookmarks_rounded), // نفس الهيدر المعتمد
            GetBuilder<TemplatesListController>(
              init: controller,
              builder: (controller) {
                return Expanded(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (_, __) {
                      if (controller.allTemplates.isEmpty) {
                        return _buildEmptyState();
                      }
                
                      return Container(
                        margin:const EdgeInsets.only(bottom: 50),
                        child: 
                       ListView.builder(
                        
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: controller.allTemplates.length,
                        itemBuilder: (_, i) {
                          final t = controller.allTemplates[i];
                          final rows = t.numOfRows ;
                          final cols = t.numOfColumns ;
                          final total = rows * cols;
                          final templateName = t.name; // ?? "قالب بدون اسم";
                
                          return _buildTemplateCard(
                            context, 
                            t, i, 
                            templateName, 
                            total, rows, cols,
                            // controller.preview,
                            // controller.delete,
                            // controller.openEditForm 
                          );
                        },
                      ));
                    },
                  ),
                );
              }
            ),
            //_footer(), // نفس الفوتر المعتمد
          ],
        ),
        floatingActionButton: FloatingButton(
          text: "اضافة قالب",
          onPressed: ()
          {
            Get.toNamed(AppRoutes.addTemplate)?.then((r){
             controller.getAll();
            });
          },
          // onPressed: controller.openAddForm,
          iconBtn: Icons.add_circle_outline_outlined,
          )
       
      ),
    );
  }

 
  Widget _buildTemplateCard(
    BuildContext context, 
    PrintTemplatesModel t, 
    int index, 
    String name, 
    int total, 
    int rows, 
    int cols,
    // Function(int id) onPreview ,
    // Function(int id) onDelete,
    // Function(int index) onEdit
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // خلفية مصغرة للكرت
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade600]),
                image: DecorationImage(
                  image: MemoryImage(t.image)
                ),// != null ? DecorationImage(image: t.image, fit: BoxFit.cover) : null,
              ),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xff0F172A))),
                      _infoBadge("$total كرت", const Color(0xff2563EB)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _gridDetail(Icons.table_rows_rounded, "صفوف: $rows"),
                      const SizedBox(width: 15),
                      _gridDetail(Icons.view_column_rounded, "أعمدة: $cols"),
                      const Spacer(),
                       Text("${t.withPassword ? "مع":"بدون"} كلمة مرور", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 0.5)),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: "فتح المعاينة",
                          icon: Icons.remove_red_eye_rounded,
                          color: const Color(0xff1E3C72),
                          onTap: () {
                            // final dummyBatchData = {'total': total, 'prefix': 'USR-', 'suffix': '', 'name': name};
                            // onPreview(t.id);
                            controller.preview(t.id);
                            // Navigator.push(context, MaterialPageRoute(builder: (_) => TemplatePreviewPage(
                            //   controller: c, templateIndex: index, batchData: dummyBatchData,
                            // )));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      _editButton(() {
                        // showErrorDialog(content: t.name);
                        // onEdit(index);
                        //controller.openEditForm(index);
                        Get.toNamed(AppRoutes.editTemplate, arguments: controller.allTemplates[index])?.then((r)=>controller.getAll());
                        // Get.to(PrintTemplatesDesignView(
                        //   designerController: TemplatesController(),
                        //   isEdit: false,
                        // ));
                      }),

                      const SizedBox(width: 10),
                      
                      _deleteButton(() => _confirmDelete(context,t.id,controller.delete)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= المكونات الصغيرة ================= */
  Widget _gridDetail(IconData icon, String txt) => Row(
    children: [
      Icon(icon, size: 14, color: Colors.blueGrey),
      const SizedBox(width: 4),
      Text(txt, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _infoBadge(String txt, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
    child: Text(txt, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    ),
  );

  Widget _deleteButton(VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
    ),
  );

  Widget _editButton(VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
      child: const Icon(Icons.mode_edit_outline_outlined, color: Colors.purple, size: 22),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.folder_open_rounded, size: 70, color: Colors.grey.shade300),
        const SizedBox(height: 15),
        const Text("لا توجد قوالب محفوظة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    ),
  );

  Widget _footer() => Container(height: 30, width: double.infinity, color: const Color(0xff0F172A), child: const Center(child: Text("Micronet Professional Edition v4.5", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))));

  void _confirmDelete(BuildContext context, int id,Function(int) onDelete) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("حذف القالب؟"),
        content: const Text("سيتم حذف تصميم القالب نهائياً من الذاكرة."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("تراجع")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("حذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      onDelete(id);
    }
  }
}

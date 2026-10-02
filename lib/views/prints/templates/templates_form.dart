import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import '/controllers/print/template_design_controller.dart';
import '../../../controllers/prints/templates/templates_list_controller.dart';
// import '../print/saved_templates_view.dart';

// class PrintTemplatesDesignView extends StatefulWidget {
//   final TemplatesListController designerController;
//   const PrintTemplatesDesignView({super.key,required this.designerController});

//   @override
//   State<PrintTemplatesDesignView> createState() => _PrintTemplatesDesignViewState();
// }

class PrintTemplatesDesignView extends StatelessWidget {
  final TemplatesListController designerController;
  final bool isEdit;
  const PrintTemplatesDesignView({super.key,required this.designerController,required this.isEdit });
  // final TemplatesListController designerController = Get.put(TemplatesListController());


  

  @override
  Widget build(BuildContext context) {
    double screenWidth = ((MediaQuery.of(context).size.width ) );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        body: Column(
          children: [
            _circleAvatarHeader(context), 
            Expanded(
              child: AnimatedBuilder(
                animation: designerController,
                builder: (_, __) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: GetBuilder<TemplatesListController>(
                    init: TemplatesListController(),
                    builder: (controller) {
                      return Column(
                        children: [
                          Column(
                            children: [
                              textFieldWithButton(
                                controller.profileName, 
                                isEdit?controller.editOne : controller.addOne,
                                btnLabel: 'save',
                              ),
                              const SizedBox(height: 5,),
                              // item settings container
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
                                height: 200, // كبرنا المساحة قليلاً لتأخذ راحتها
                                alignment: Alignment.center,
                                // استخدمنا ScrollView عشان لو الكرت كبير ما ينضغط ويخرب الحسبة
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Container(
                                      width: (controller.itemWidth * 2),
                                      height: (controller.itemHeight * 2),
                                      decoration: BoxDecoration(
                                        border: Border.all(),
                                        image: DecorationImage(
                                          image: controller.templateImage,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          // حقل اسم المستخدم
                                          buildFieldPosition(
                                            controller.x.value, 
                                            controller.y.value, 
                                            controller.itemWidth, 
                                            controller.itemHeight, 
                                            controller.username, 
                                            controller.usernameText.text, 
                                            controller.usernameFontSize.toDouble(), 
                                            const Color.fromARGB(86, 33, 149, 243), 
                                            (details) {
                                            controller.x.value = (controller.x.value +details.delta.dx).clamp(0.0,(controller.itemWidth *2) -30);
                                            controller.y.value = (controller.y.value +details.delta.dy).clamp(0.0,(controller.itemHeight *2) -20);
                                            controller.update();
                                            },
                                          ),
                                      
                                          // حقل كلمة المرور
                                          buildFieldPosition(
                                            controller.x2.value, 
                                            controller.y2.value, 
                                            controller.itemWidth, 
                                            controller.itemHeight, 
                                            controller.password, 
                                            controller.passwordText.text, 
                                            controller.passwordFontSize.toDouble(), 
                                            const Color.fromARGB(86, 244, 67, 54), 
                                            (details) {
                                            // تم تعديل الـ clamp لتجنب القيم السالبة والأخطاء
                                            controller.x2.value = (controller.x2.value +details.delta.dx).clamp(0.0,(controller.itemWidth *2) -30);
                                            controller.y2.value = (controller.y2.value +details.delta.dy).clamp(0.0,(controller.itemHeight *2) -20);
                                            controller.update();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 5,),
                          // page settings container
                          whiteContainer(
                            Column(
                            children:[
                               Row(
                                // mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("تجربة اسم مستخدم"),
                                  const SizedBox(width: 35,),
                                  if(controller.password)
                                  const Text("تجربة كلمة مرور"),
                                ],
                              ),
                              SizedBox(
                                height: 35,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(width: ((screenWidth+20)/3), child: textFieldWithOutButton(controller.usernameText,padding: 1,onChanged: (v){controller.update();})),
                                    if(controller.password)
                                    SizedBox(width: ((screenWidth+20)/3), child: textFieldWithOutButton(controller.passwordText,padding: 1,onChanged: (v){controller.update();})),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(children: [
                                gridControl(
                                  "عدد الصفوف", 
                                  controller.numrows, 
                                  min: 10,max: 20,
                                  func: (p0) => controller.update(),
                                  Icons.table_rows_rounded
                                ), 
                                gridControl(
                                  "عدد الاعمدة", 
                                  controller.numcolumns, 
                                  min: 2,max: 5,
                                  func: (p0) => controller.update(),
                                  Icons.view_column_rounded
                                ),
                              ]),
                              const Divider(height: 10, thickness: 0.5),
                              Row(children: [
                                gridControl(
                                  'حجم اسم المستخدم', 
                                  controller.usernameFontSize, 
                                  func: (p0) => controller.update(),
                                  Icons.person_outline,
                                  min: 8,max: 30,
                                ), 
                                gridControl(
                                  'حجم كلمة المرور', 
                                  controller.passwordFontSize, 
                                  func: (p0) => controller.update(),
                                  Icons.password,
                                  min: 8,max: 30,
                                )
                              ]),
                              const SizedBox(height: 5),
                              modernSwitch(
                                controller.password,
                                controller.isWithPassword2,
                                text: '${controller.password?"مع":"بدون"} ${"كلمة مرور"}  (انقر للتغيير)'
                              ),
                              const Divider(height: 10, thickness: 0.5),
                              
                              
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  gradientButton(
                                    width: ((screenWidth/3)+20),
                                    onPressed: controller.pickImage,
                                    icon: Icons.image_outlined,
                                    label: 'اختيار صورة',
                                    colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
                                  ),
                                  // const SizedBox(width: 30,),
                                  // preview btn
                                  gradientButton(
                                    width: ((screenWidth/3)+20),
                                    onPressed: controller.preview,
                                    icon: Icons.remove_red_eye_rounded,
                                    label: 'معاينة',
                                    colors: [Colors.lightGreen.shade700, Colors.lime.shade900],
                                  ),
                                ],
                              ),
                              // const SizedBox(height: 10),
                              
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                locationControl(
                                  "تحريك مكان اسم المستخدم", 
                                  controller.x, 
                                  controller.y, 
                                  func: (p0) => controller.update(),
                                  Icons.person_outline,
                                  top: 0,left: 0 ,
                                  bottom: (controller.itemHeight * 2)-20,
                                  right: (controller.itemWidth * 2)-30
                                ), 
                                const SizedBox(width: 20,),
                                locationControl(
                                  "تحريك مكان كلمة المرور", 
                                  controller.x2, 
                                  controller.y2, 
                                  func: (p0) => controller.update(),
                                  Icons.password,
                                  top: 0,left: 0 ,
                                  bottom: (controller.itemHeight * 2)-20,
                                  right: (controller.itemWidth * 2)-30,
                                  color: Colors.red
                                ), 
                              ]),
                              ],
                            )
                          ),
                          const SizedBox(height: 5),    
                          gradientButton(
                                    //width: ((screenWidth/3)+20),
                                    height: 55,
                                    onPressed: isEdit?controller.editOne : controller.addOne,
                                    icon: isEdit? Icons.save_rounded : Icons.add_circle_outline_outlined,
                                    label: isEdit ? "حفظ" : "اضافة",
                                    colors: const [Color(0xff1E3C72), Color(0xff2563EB)],
                                  ),                     
                          //Center(child: Text("${'numcards_inpage'}: ${(controller.numrows.value * controller.numcolumns.value)}")),
                        ],
                      );
                    }
                  ),
                ),
              ),
            ),
            //_footer(),
          ],
        ),
      ),
    );
  }

  /* ================= 1. حقل اسم القالب بتصميم أنيق ================= */

  /* ================= 2. الهيدر المطور ================= */
  Widget _circleAvatarHeader(BuildContext context) => Container(
        height: 160,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xff0F172A), Color(0xff1E3C72), Color(0xff2563EB)]
          ),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.auto_awesome_motion_rounded, color: Color(0xff1E3C72), size: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("ستوديو تصميم القوالب", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
            ),
            Positioned(top: 45, right: 20, child: _glassBackButton(context)),
          ],
        ),
      );

  Widget _glassBackButton(BuildContext context) => InkWell(
    onTap: () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
    ),
  );

  /* ================= 3. لوحة التصميم ================= */


  /* ================= 4. شريط التحكم الذكي ================= */



  /* ================= 5. إعدادات الشبكة ================= */



  /* ================= 6. المعاينة الحية الملتزمة بالشبكة ================= */



  /* ================= 7. إضافة نص والأزرار النهائية ================= */

  // Widget _saveActions() => Column(children: [
  //   _gradientButton(
  //     onPressed: () {
  //       if (_templateNameCtrl.text.trim().isEmpty) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text("⚠️ برجاء إدخال اسم للقالب أولاً"), backgroundColor: Colors.orange)
  //         );
  //         return;
  //       }
  //       // designerController.saveTemplate();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("✅ تم حفظ القالب بنجاح"), backgroundColor: Colors.green)
  //       );
  //     },
  //     icon: Icons.save_rounded, label: "حفظ التصميم الآن", colors: [const Color(0xff059669), const Color(0xff10B981)], height: 55,
  //   ),
  //   const SizedBox(height: 12),
  //   OutlinedButton.icon(
  //     onPressed: () {}, // => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedTemplatesView(c: designerController))),
  //     icon: const Icon(Icons.folder_special_outlined),
  //     label: const Text("استعراض القوالب المحفوظة"),
  //     style: OutlinedButton.styleFrom(
  //       minimumSize: const Size(double.infinity, 50), 
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
  //       side: const BorderSide(color: Color(0xff1E3C72), width: 1.5)
  //     ),
  //   ),
  // ]);

  /* ويدجت الزر المتدرج الموحد */
  Widget _gradientButton({required VoidCallback onPressed, required IconData icon, required String label, required List<Color> colors, double? width, double height = 45}) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors), 
      borderRadius: BorderRadius.circular(15), 
      boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
    ),
  );

  Widget _footer() => Container(height: 30, width: double.infinity, color: const Color(0xff0F172A), child: const Center(child: Text("Micronet Professional Edition v4.5", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))));


}





Widget buildFieldPosition(
  double x,double y,double itemWidth,
  double itemHeight,bool visible,String text,
  double fontSize,Color background,void Function(DragUpdateDetails) onPanUpdate
){
  return Positioned(
    left: x,
    top: y,
    child: GestureDetector(
      onPanUpdate: onPanUpdate,
      child: Visibility(
        visible: visible,
        child: Container(
          color: background,
          child: Text(
              text,
              style: TextStyle(
                  fontFamily: "arial",
                  fontSize: fontSize,
                  fontWeight:FontWeight.bold
              )
            ),
        ),
      ),
    ),
  );
}




class ContinuousButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double padding;
  final double? size;

  const ContinuousButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.padding=8.0,
    this.size
  }) : super(key: key);

  @override
  State<ContinuousButton> createState() => _ContinuousButtonState();
}

class _ContinuousButtonState extends State<ContinuousButton> {
  Timer? _timer;
  bool _isHolding = false;

  void _startHolding() {
    _isHolding = true;
    // تنفيذ الدالة مرة واحدة فور الضغط (للنقرات السريعة)
    widget.onPressed(); 
    
    // الانتظار قليلاً قبل بدء التكرار السريع (لتجنب التداخل مع النقرة العادية)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isHolding) {
        // إذا استمر الضغط، كرر العملية كل 100 ملي ثانية
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          widget.onPressed(); 
        });
      }
    });
  }

  void _stopHolding() {
    _isHolding = false;
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel(); // تأكد من إيقاف المؤقت عند إزالة الزر من الشاشة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _startHolding(),
      onLongPressEnd: (_) => _stopHolding(),
      onLongPressUp: () => _stopHolding(),
      onLongPressCancel: () => _stopHolding(),
      onTap: widget.onPressed,
      // onTapDown: (_) => _startHolding(),   // عند بدء الضغط
      // onTapUp: (_) => _stopHolding(),      // عند رفع الإصبع
      // onTapCancel: _stopHolding,           // عند إلغاء الضغط (مثل سحب الإصبع بعيداً)
      child: Padding(
        padding: EdgeInsets.all(widget.padding),
        child: Icon(widget.icon, color: widget.color, size: widget.size),
      ),
    );
  }
}



Widget gridControl(String title, RxInt val, IconData icon, {int min=1, int max=20, Function(int)? func,}) => Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, size: 14, color: Colors.grey), 
            const SizedBox(width: 4), 
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))
          ]
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(color: const Color(0xffF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // استخدام الزر المخصص للزيادة
              ContinuousButton(
                icon: Icons.add_circle,
                color: Colors.blue,
                onPressed: () { 
                  if (val.value < max) {
                    val.value+=1;
                    if(func!=null)func(val.value); 
                  }
                },
              ),
              Obx(()=>Text("$val", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),),
              // استخدام الزر المخصص للنقصان
              ContinuousButton(
                icon: Icons.remove_circle,
                color: Colors.red,
                onPressed: () { 
                  if (val.value > min) {
                    val.value-=1;
                    if(func!=null)func(val.value); 
                  }
                },
              ),
            ],
          ),
        )
      ],
    ),
  );

Widget locationControl(
  String title, 
  RxDouble x, 
  RxDouble y, 
  IconData icon, 
  {
    double top = 0,
    double left = 0, 
    double bottom = 20, 
    double right = 20, 
    Function(double)? func,
    Color color=Colors.blue
  }
) => Expanded(
    child: Column(
      children: [
        // العنوان والأيقونة
        Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, size: 14, color: Colors.grey), 
            const SizedBox(width: 4), 
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))
          ]
        ),
        const SizedBox(height: 8),
        
        // لوحة التحكم بالاتجاهات
        Container(
          padding: const EdgeInsets.all(8), // إضافة بادينج بسيط لجمالية الشكل
          decoration: BoxDecoration(color: const Color(0xffF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الصف الأول: زر الأعلى (Up)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ContinuousButton(
                    icon: Icons.keyboard_arrow_up,
                    padding: 1,
                    color: color,
                    onPressed: () { 
                      if (y.value > top) {
                        y.value -= 1;
                        if(func != null) func(y.value); 
                      }
                    },
                  ),
                ],
              ),
              
              // الصف الثاني: أزرار اليمين واليسار (Left & Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // زر اليمين
                  ContinuousButton(
                    icon: Icons.keyboard_arrow_right,
                    padding: 1,
                    color: color,
                    onPressed: () { 
                      if (x.value < right) {
                        x.value += 1;
                        if(func != null) func(x.value); 
                      }
                    },
                  ),
                  
                  const SizedBox(width: 30), // مسافة فارغة في المنتصف لتبدو كلوحة تحكم
                  
                  // زر اليسار
                  ContinuousButton(
                    icon: Icons.keyboard_arrow_left,
                    padding: 1,
                    color: color,
                    onPressed: () { 
                      if (x.value > left) {
                        x.value -= 1;
                        if(func != null) func(x.value); 
                      }
                    },
                  ),
                ],
              ),
              
              // الصف الثالث: زر الأسفل (Down)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ContinuousButton(
                    icon: Icons.keyboard_arrow_down,
                    padding: 1,
                    color: color,
                    onPressed: () { 
                      if (y.value < bottom) {
                        y.value += 1;
                        if(func != null) func(y.value); 
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    ),
  );



// Widget gridControl(String title, int val, Function(int) func, IconData icon, {int min=1, int max=20}) => Expanded(
//     child: Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center, 
//           children: [
//             Icon(icon, size: 14, color: Colors.grey), 
//             const SizedBox(width: 4), 
//             Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))
//           ]
//         ),
//         const SizedBox(height: 8),
//         Container(
//           margin: const EdgeInsets.symmetric(horizontal: 5),
//           decoration: BoxDecoration(color: const Color(0xffF1F5F9), borderRadius: BorderRadius.circular(12)),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // استخدام الزر المخصص للزيادة
//               ContinuousButton(
//                 icon: Icons.add_circle,
//                 color: Colors.blue,
//                 onPressed: () { 
//                   if (val < max) func(val + 1); 
//                 },
//               ),
//               Text("$val", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//               // استخدام الزر المخصص للنقصان
//               ContinuousButton(
//                 icon: Icons.remove_circle,
//                 color: Colors.red,
//                 onPressed: () { 
//                   if (val > min) func(val - 1); 
//                 },
//               ),
//             ],
//           ),
//         )
//       ],
//     ),
//   );




Widget whiteContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
      child: child
    );
  }


Widget modernSwitch(
  bool showPassword,
  void Function(bool) togglePass,
  {String text="عرض كلمة السر في المعاينة"}
) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: const Color(0xffF1F5F9), borderRadius: BorderRadius.circular(12)),
    child: SwitchListTile(
      title: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      value: showPassword,
      onChanged: (v) => togglePass(v),
      activeColor: const Color(0xff2563EB),
      dense: true,
    ),
  );

Widget gradientButton({required VoidCallback onPressed, required IconData icon, required String label, required List<Color> colors, double? width, double height = 45}) 
=> Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors), 
      borderRadius: BorderRadius.circular(15), 
      boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
    ),
  );

Widget textFieldWithButton(
  TextEditingController controller,
  void Function() onPressed,
  {
    String hint="أضف اسماً مميزاً",
    String btnLabel="إضافة",
    IconData icon=Icons.add,
    List<Color> colors=const [Color(0xff1E3C72), Color(0xff2563EB)],
    double btnWidth=100,
    double btnHeight=40,
  }
) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade50)),
    child: Row(children: [
      const SizedBox(width: 10),
      const Icon(Icons.text_fields_rounded, color: Colors.grey, size: 20),
      const SizedBox(width: 10),
      Expanded(child: TextField(controller: controller,textAlign: TextAlign.center, decoration: InputDecoration(hintText: hint, border: InputBorder.none,suffixIcon:const Icon(Icons.signal_cellular_null,color: Colors.transparent,), hintStyle: const TextStyle(fontSize: 15)))),
      // gradientButton(
      //   onPressed: onPressed,
      //   icon: icon, label: btnLabel, colors: colors, width: btnWidth, height: btnHeight,
      // ),
    ]),
  );

Widget textFieldWithOutButton(
  TextEditingController controller,
  {
    String hint="مثال : ########",
    double padding=16,
    void Function(String)? onChanged
  }
) => Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(((padding/4)+1)*4), 
        border: Border.all(color: Colors.blue.shade100)
      ),
      child: TextField(
        controller: controller, 
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint, 
          border: InputBorder.none, 
          // hintStyle: TextStyle(fontSize: ((padding/4)-1)*4)
        ),
        onChanged: onChanged,
      )
    );

// => Column(
//   children: [
//     Container(
//         padding: const EdgeInsets.all(6),
//         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade50)),
//         child: Row(children: [
//           const SizedBox(width: 10),
//           const Icon(Icons.text_fields_rounded, color: Colors.grey, size: 20),
//           const SizedBox(width: 10),
//           Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: InputBorder.none, hintStyle: const TextStyle(fontSize: 12)))),
//         ]),
//       ),
//   ],
// );
  






import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/prints/templates/base_template_controller.dart';
import '../../widgets/shared/layouts/gradient_button.dart';


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




// ----------------- Canvas Builder ----------------- //
Widget buildCanvasArea(BaseTemplateController controller) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
    height: 200,
    alignment: Alignment.center,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          width: (controller.itemWidth * 2),
          height: (controller.itemHeight * 2),
          decoration: BoxDecoration(
            border: Border.all(),
            image: DecorationImage(image: controller.templateImage, fit: BoxFit.fill),
          ),
          child: Stack(
            children: [
              buildFieldPosition(
                controller.x.value, controller.y.value, controller.itemWidth, controller.itemHeight, 
                controller.username, controller.usernameText.text, controller.usernameFontSize.toDouble(), 
                const Color.fromARGB(86, 33, 149, 243), 
                (details) {
                  controller.x.value = (controller.x.value + details.delta.dx).clamp(0.0, (controller.itemWidth * 2) - 30);
                  controller.y.value = (controller.y.value + details.delta.dy).clamp(0.0, (controller.itemHeight * 2) - 20);
                  controller.update();
                },
              ),
              buildFieldPosition(
                controller.x2.value, controller.y2.value, controller.itemWidth, controller.itemHeight, 
                controller.password, controller.passwordText.text, controller.passwordFontSize.toDouble(), 
                const Color.fromARGB(86, 244, 67, 54), 
                (details) {
                  controller.x2.value = (controller.x2.value + details.delta.dx).clamp(0.0, (controller.itemWidth * 2) - 30);
                  controller.y2.value = (controller.y2.value + details.delta.dy).clamp(0.0, (controller.itemHeight * 2) - 20);
                  controller.update();
                },
              ),
            ],
          ),
        ),
      ),
    )
  );
}
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

Widget whiteContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
      child: child
    );
  }

// ----------------- Settings Builder ----------------- //
Widget buildSettingsArea(BaseTemplateController controller, double screenWidth) {
  return whiteContainer(
    Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("تجربة اسم مستخدم"),
            const SizedBox(width: 35),
            if (controller.password) const Text("تجربة كلمة مرور"),
          ],
        ),
        SizedBox(
          height: 35,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: ((screenWidth + 20) / 3), child: textFieldWithOutButton(controller.usernameText, padding: 1, onChanged: (v) => controller.update())),
              if (controller.password)
                SizedBox(width: ((screenWidth + 20) / 3), child: textFieldWithOutButton(controller.passwordText, padding: 1, onChanged: (v) => controller.update())),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          gridControl("عدد الصفوف", controller.numrows, min: 10, max: 20, func: (p0) => controller.update(), Icons.table_rows_rounded),
          gridControl("عدد الاعمدة", controller.numcolumns, min: 2, max: 5, func: (p0) => controller.update(), Icons.view_column_rounded),
        ]),
        const Divider(height: 10, thickness: 0.5),
        Row(children: [
          gridControl('حجم اسم المستخدم', controller.usernameFontSize, func: (p0) => controller.update(), Icons.person_outline, min: 8, max: 30),
          gridControl('حجم كلمة المرور', controller.passwordFontSize, func: (p0) => controller.update(), Icons.password, min: 8, max: 30)
        ]),
        const SizedBox(height: 5),
        modernSwitch(controller.password, controller.isWithPassword2, text: '${controller.password ? "مع" : "بدون"} ${"كلمة مرور"}  (انقر للتغيير)'),
        const Divider(height: 10, thickness: 0.5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GradientButton(width: ((screenWidth / 3) + 20), onPressed: controller.pickImage, icon: Icons.image_outlined, label: 'اختيار صورة', colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900]),
            GradientButton(width: ((screenWidth / 3) + 20), onPressed: controller.preview, icon: Icons.remove_red_eye_rounded, label: 'معاينة', colors: [Colors.lightGreen.shade700, Colors.lime.shade900]),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            locationControl("تحريك مكان اسم المستخدم", controller.x, controller.y, func: (p0) => controller.update(), Icons.person_outline, top: 0, left: 0, bottom: (controller.itemHeight * 2) - 20, right: (controller.itemWidth * 2) - 30),
            const SizedBox(width: 20),
            locationControl("تحريك مكان كلمة المرور", controller.x2, controller.y2, func: (p0) => controller.update(), Icons.password, top: 0, left: 0, bottom: (controller.itemHeight * 2) - 20, right: (controller.itemWidth * 2) - 30, color: Colors.red),
          ]
        ),
      ],
    )
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







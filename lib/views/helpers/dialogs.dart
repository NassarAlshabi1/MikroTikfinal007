
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showErrorDialog({String title="Error",Color titleColor=Colors.red,String content="...",String action="Done"}){
  Get.dialog(
    AlertDialog(
      title: Text(title,style: TextStyle(color: titleColor)),
      content: Text(content),
      actions: [
        TextButton(onPressed: ()=>Get.back(), child: Text(action,))
      ],
      scrollable: true,
    )
  );
}



Future<bool> showConfirmDialog({
  String title = 'تأكيد',
  String content = 'هل أنت متأكد من القيام بهذه العملية؟',
}) async {
  // نستخدم await لانتظار رد المستخدم من الديالوج
  final bool? result = await Get.dialog<bool>(
    AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            // يغلق الديالوج ويرجع false
            Get.back(result: false);
          },
          child: const Text('لا'),
        ),
        ElevatedButton(
          onPressed: () {
            // يغلق الديالوج ويرجع true
            Get.back(result: true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // لون الزر لتنبيه المستخدم (اختياري)
            foregroundColor: Colors.white,
          ),
          child: const Text('نعم'),
        ),
      ],
    ),
    // يمنع إغلاق الديالوج عند النقر في الفراغ خارجه لضمان اختيار المستخدم
    barrierDismissible: false, 
  );

  // إرجاع النتيجة، وإذا كانت null (مثلاً لو أُغلق الديالوج بطريقة أخرى) نرجع false افتراضياً
  return result ?? false; 
}






void showLoadingDialog({String text="processing..."}) {
  Get.dialog(
    AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Text(text),
        ],
      ),
    )
  );
}


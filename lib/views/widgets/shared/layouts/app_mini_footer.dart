import 'package:flutter/material.dart';

class AppMiniFooter extends StatelessWidget {
  final Widget title;
  final Widget? subTitle; // جعلناها اختيارية وتقبل Null

  const AppMiniFooter({
    super.key, 
    required this.title, 
    this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.blueGrey.shade50)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30), 
          topRight: Radius.circular(30),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        spreadRadius: 1, 
        blurRadius: 10 ,
        offset: const Offset(0, -3), 
      ),
    ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            title,
            // التحقق مما إذا كان subTitle موجوداً قبل عرضه
            if (subTitle != null) ...[
              const SizedBox(height: 2),
              subTitle!,
            ],
          ],
        ),
      ),
    );
  }
}
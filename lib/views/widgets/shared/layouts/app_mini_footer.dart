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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        border: Border(top: BorderSide(color: const Color(0xFF243352))),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22), 
          topRight: Radius.circular(22),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        spreadRadius: 1, 
        blurRadius: 8 ,
        offset: const Offset(0, -2), 
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
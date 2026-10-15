import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';

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
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.border)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22), 
          topRight: Radius.circular(22),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
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
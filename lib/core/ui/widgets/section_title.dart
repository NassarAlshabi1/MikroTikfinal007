import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 15,
            decoration: BoxDecoration(
              color: AppColors.info,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

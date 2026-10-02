import 'package:flutter/material.dart';

class FloatingButton extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? iconBtn;
  final VoidCallback? onPressed; 

  const FloatingButton({
    super.key, 
    required this.text,
    this.iconBtn, // تم التعديل لتطابق اسم المتغير وجعلها اختيارية
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: color ?? const Color(0xFF1E3A8A),
      onPressed: onPressed,
      label: Text(
        text, 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      icon: iconBtn != null ? Icon(iconBtn, color: Colors.white) : null,
    );
  }
}
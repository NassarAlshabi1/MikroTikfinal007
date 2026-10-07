import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModernInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isReadOnly;
  final bool isNumber; // 👈 إضافة المتغير لدعم لوحة الأرقام

  const ModernInput({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.isReadOnly = false,
    this.isNumber = false, // 👈 القيمة الافتراضية نص عادي
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isReadOnly ? const Color(0xFF243352) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isReadOnly ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        inputFormatters: isNumber 
            ? [FilteringTextInputFormatter.digitsOnly] 
            : [],
        textAlign: TextAlign.center,
        // 👈 تحديد نوع الكيبورد بناءً على المتغير
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isReadOnly ? const Color(0xFF8FA3C0) : const Color(0xFF94A3B8), 
            fontSize: 12
          ),
          prefixIcon: Icon(
            icon, 
            color: isReadOnly ? const Color(0xFF8FA3C0) : const Color(0xFF3B82F6), 
            size: 20
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: TextStyle(
          color: isReadOnly ? const Color(0xFF94A3B8) : Colors.black,
          fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

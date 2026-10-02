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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isReadOnly ? const Color(0xFFE2E8F0) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            color: isReadOnly ? Colors.blueGrey.shade400 : Colors.blueGrey, 
            fontSize: 13
          ),
          prefixIcon: Icon(
            icon, 
            color: isReadOnly ? Colors.blueGrey.shade400 : const Color(0xFF1E3A8A), 
            size: 20
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: TextStyle(
          color: isReadOnly ? Colors.blueGrey.shade600 : Colors.black,
          fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

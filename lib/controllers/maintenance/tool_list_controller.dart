import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/maintenance_api.dart';
import '../../models/maintenance_tools.dart';

/// متحكم عرض أي قائمة من RouterOS بشكل عام (بحث + تحديث + تفاصيل).
class ToolListController extends GetxController {
  ToolListController(this.tool);

  final MaintenanceTool tool;
  final searchCtrl = TextEditingController();

  final RxList<Map<String, String>> rows = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> filteredRows = <Map<String, String>>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = "".obs;
  final RxString searchQuery = "".obs;

  RouterMenuSpec get menu => tool.menu!;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = "";

    final response = await MaintenanceApi.printList(menu);

    isLoading.value = false;

    if (response.status && response.data != null) {
      rows.assignAll(response.data!);
      _applySearch();
    } else {
      rows.clear();
      filteredRows.clear();
      errorMessage.value = response.message;
    }
  }

  void setSearch(String query) {
    searchQuery.value = query;
    _applySearch();
  }

  void _applySearch() {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      filteredRows.assignAll(rows);
      return;
    }

    filteredRows.assignAll(
      rows.where((row) {
        return row.values.any((value) => value.toLowerCase().contains(query));
      }).toList(),
    );
  }

  /// العمود الرئيسي لعرضه كعنوان للصف.
  String primaryValue(Map<String, String> row) {
    for (final key in menu.primaryKeys) {
      final value = row[key];
      if (value != null && value.isNotEmpty) return value;
    }
    // أول قيمة غير فارغة
    for (final entry in row.entries) {
      if (entry.value.isNotEmpty) return entry.value;
    }
    return "—";
  }

  String secondaryValue(Map<String, String> row) {
    final parts = <String>[];
    for (final entry in row.entries) {
      if (entry.key.startsWith('.') || entry.value.isEmpty) continue;
      if (entry.value == primaryValue(row)) continue;
      parts.add("${entry.key}: ${entry.value}");
      if (parts.length >= 3) break;
    }
    return parts.join(" • ");
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}

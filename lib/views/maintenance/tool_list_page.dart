import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/maintenance/tool_list_controller.dart';
import '../widgets/shared/layouts/sub_page_header.dart';

/// عارض عام لأي قائمة من RouterOS (IP / DHCP / ARP / NAT / Firewall / Queue ...).
class ToolListPage extends GetView<ToolListController> {
  const ToolListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: controller.tool.title,
              subtitle: controller.tool.subtitle,
              icon: controller.tool.icon,
              goBack: Get.back,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: Column(
                  children: [
                    _searchBar(),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (controller.errorMessage.value.isNotEmpty) {
                        return Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                "تعذّر قراءة القائمة:\n${controller.errorMessage.value}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), height: 1.6),
                              ),
                            ),
                          ),
                        );
                      }

                      if (controller.filteredRows.isEmpty) {
                        return const Expanded(
                          child: Center(
                            child: Text(
                              "لا توجد عناصر في هذه القائمة",
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                        );
                      }

                      return Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: controller.filteredRows.length,
                          itemBuilder: (context, index) {
                            final row = controller.filteredRows[index];
                            return _rowCard(row, index + 1);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.searchCtrl,
                onChanged: controller.setSearch,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: "بحث في العناصر...",
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: "تحديث",
            onPressed: controller.load,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E3A8A)),
          ),
        ],
      ),
    );
  }

  Widget _rowCard(Map<String, String> row, int index) {
    final primary = controller.primaryValue(row);
    final secondary = controller.secondaryValue(row);
    final isDisabled = (row["disabled"] ?? "").toLowerCase() == "true";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDisabled ? Border.all(color: const Color(0xFFFCA5A5)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetails(row),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: controller.tool.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$index",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: controller.tool.color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (secondary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          secondary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(Map<String, String> row) {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(controller.tool.icon, color: controller.tool.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.tool.title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(),
                ...row.entries.where((entry) => entry.value.isNotEmpty).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SelectableText(
                                entry.value,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

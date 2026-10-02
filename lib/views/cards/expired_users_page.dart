import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/expired_users_api.dart';
import '../../controllers/cards/expired_users_controller.dart';
import '../widgets/shared/layouts/gradient_button.dart';
import '../widgets/shared/layouts/sub_page_header.dart';

/// صفحة "المستخدمون المنتهون": فحص ذكي يقارن uptime مع limit-uptime
/// ويحذف فقط من استهلك مدته كاملة.
class ExpiredUsersPage extends GetView<ExpiredUsersController> {
  const ExpiredUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: "المستخدمون المنتهون",
              subtitle: "فحص ذكي للمدة المستهلكة وحذف المنتهين فقط",
              icon: Icons.auto_delete_rounded,
              goBack: Get.back,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return _errorState();
                }

                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: controller.scan,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          children: [
                            _statsCard(),
                            _optionsCard(),
                            const SizedBox(height: 14),
                            _titleRow(),
                            const SizedBox(height: 8),
                            ..._userCards(),
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ),
                    _actionBar(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== حالة الخطأ =====================
  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 46, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.7),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: "إعادة الفحص",
              icon: Icons.refresh_rounded,
              height: 46,
              onPressed: controller.scan,
            ),
          ],
        ),
      ),
    );
  }

  // ===================== بطاقة الإحصاءات =====================
  Widget _statsCard() {
    final result = controller.scanResult.value;
    final exhausted = result?.exhausted.length ?? 0;
    final running = result?.stillRunning.length ?? 0;
    final total = result?.totalUsers ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _stat("إجمالي المستخدمين", total, Colors.white),
              _stat("استهلكوا المدة", exhausted, const Color(0xFF4ADE80)),
              _stat("لم يكملوا بعد", running, const Color(0xFFFCD34D)),
            ],
          ),
          const Divider(color: Colors.white24, height: 22),
          Row(
            children: [
              _stat("بلا حدود", result?.withoutLimits ?? 0, Colors.white70),
              _stat("غير قابل للتحليل", result?.unparsable ?? 0, const Color(0xFFFDA4AF)),
              _stat("المحدد للحذف", controller.selectedCount, const Color(0xFF60A5FA)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${result?.versionLabel ?? 'إصدار غير محدد'}"
                  "${(result?.clearedProfileCount ?? 0) > 0 ? " • منها ${result!.clearedProfileCount} بالباقة المُزالة (معيار v6)" : ""}"
                  "${(result?.stateUsedCount ?? 0) > 0 ? " • منها ${result!.stateUsedCount} بحالة used (معيار v7)" : ""}",
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 10.5),
          ),
          const SizedBox(height: 5),
          Text(
            "$value",
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }

  // ===================== خيارات الفحص =====================
  Widget _optionsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Obx(
            () => SwitchListTile(
              dense: true,
              value: controller.includeBytesOnly.value,
              activeColor: const Color(0xFF2563EB),
              title: const Text(
                "إضافة من انتهى رصيد بياناته فقط",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: const Text(
                "مستخدمون لم تكتمل مدتهم لكن نفدت باقتهم (اختياري)",
                style: TextStyle(fontSize: 11),
              ),
              onChanged: controller.setIncludeBytesOnly,
            ),
          ),
          const Divider(height: 1),
          Obx(
            () => CheckboxListTile(
              dense: true,
              value: controller.isAllSelected,
              activeColor: const Color(0xFF10B981),
              title: const Text(
                "تحديد الكل / إلغاء الكل",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onChanged: (value) => controller.toggleAll(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleRow() {
    return Row(
      children: [
        const Text(
          "المؤهلون للحذف",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B)),
        ),
        const Spacer(),
        IconButton(
          tooltip: "إعادة الفحص",
          onPressed: controller.scan,
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E3A8A)),
        ),
      ],
    );
  }

  // ===================== قائمة المستخدمين =====================
  List<Widget> _userCards() {
    final users = controller.displayed;

    if (users.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            children: [
              Icon(Icons.verified_rounded, size: 42, color: Color(0xFF10B981)),
              SizedBox(height: 10),
              Text(
                "لا يوجد مستخدمون استهلكوا مدتهم كاملة ✅",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), height: 1.6),
              ),
            ],
          ),
        ),
      ];
    }

    return users.map((user) => _userCard(user)).toList();
  }

  Widget _userCard(ExpiredUserCandidate user) {
    final reason = user.expiredReason;
    final reasonColor = _reasonColor(reason);

    return Obx(() {
      final selected = controller.selection[user.id] == true;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB).withOpacity(0.5) : const Color(0xFFE2E8F0),
          ),
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
            onTap: () => controller.toggleUser(user.id, !selected),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: selected,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (value) => controller.toggleUser(user.id, value),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.username.isEmpty ? "بلا اسم" : user.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            _badge(reason, reasonColor),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${user.profile} • المستهلك: ${user.usedLabel} / الحد: ${user.limitLabel}",
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (user.percent / 100).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation(
                              user.percent >= 100 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${user.percent}% مستهلك"
                          "${user.usedBytes > 0 ? " • البيانات: ${user.readableUsedBytes}/${user.readableLimitBytes}" : ""}",
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// لون الشارة حسب سبب الانتهاء (معايير v6 / v7).
  Color _reasonColor(String reason) {
    switch (reason) {
      case 'انتهت المدة':
        return const Color(0xFFEF4444);
      case 'الباقة مُزالة (v6)':
        return const Color(0xFF7C3AED);
      case 'الباقة مستهلكة (v7)':
        return const Color(0xFF0EA5E9);
      case 'انتهى الرصيد':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  // ===================== شريط الحذف =====================
  Widget _actionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x11000000), blurRadius: 14, offset: Offset(0, -4)),
        ],
      ),
      child: Obx(
        () => GradientButton(
          label: controller.isDeleting.value
              ? "جاري الحذف..."
              : "حذف المحدد (${controller.selectedCount})",
          icon: Icons.delete_forever_rounded,
          height: 50,
          colors: controller.selectedCount == 0
              ? const [Color(0xFF94A3B8), Color(0xFFCBD5E1)]
              : const [Color(0xFF991B1B), Color(0xFFEF4444)],
          onPressed: controller.isDeleting.value || controller.selectedCount == 0
              ? null
              : controller.deleteSelected,
        ),
      ),
    );
  }
}

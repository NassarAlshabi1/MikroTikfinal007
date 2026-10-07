import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/expired_users_api.dart';
import 'package:mikronet/core/app_theme.dart';
import 'package:mikronet/controllers/cards/expired_users_controller.dart';
import '../widgets/shared/layouts/gradient_button.dart';
import '../widgets/shared/layouts/sub_page_header.dart';

/// صفحة المستخدمين المؤهلين للانتهاء، اعتمادًا على نتيجة فحص الراوتر الفعلية.
class ExpiredUsersPage extends GetView<ExpiredUsersController> {
  const ExpiredUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            const PremiumHeader(
              title: 'المستخدمون المنتهون',
              subtitle: 'فحص المدة والرصيد قبل حذف المستخدمين المؤهلين فقط',
              icon: Icons.auto_delete_rounded,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) return _loadingState();
                if (controller.errorMessage.value.isNotEmpty) return _errorState();

                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: controller.scan,
                        color: AppColors.info,
                        backgroundColor: AppColors.card,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                          children: [
                            _statsCard(),
                            const SizedBox(height: 12),
                            _optionsCard(),
                            const SizedBox(height: 14),
                            _listHeading(),
                            const SizedBox(height: 8),
                            ..._userCards(),
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

  Widget _loadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.info),
          SizedBox(height: 12),
          Text('جارٍ فحص مستخدمي User Manager…',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 30),
            ),
            const SizedBox(height: 12),
            const Text('تعذّر فحص المستخدمين',
                style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.scan,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة الفحص'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsCard() {
    final result = controller.scanResult.value;
    final exhausted = result?.exhausted.length ?? 0;
    final running = result?.stillRunning.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _stat('إجمالي المستخدمين', result?.totalUsers ?? 0, Colors.white),
              _stat('انتهت مدتهم', exhausted, AppColors.success),
              _stat('ما زالوا صالحين', running, AppColors.warning),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white.withOpacity(0.18), height: 1),
          ),
          Row(
            children: [
              _stat('بلا حدود', result?.withoutLimits ?? 0, Colors.white70),
              _stat('تعذّر تحليلهم', result?.unparsable ?? 0, const Color(0xFFFDA4AF)),
              _stat('المحدد للحذف', controller.selectedCount, const Color(0xFF93C5FD)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(_scanMethodLabel(result),
                      style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.4)),
                ),
                IconButton(
                  tooltip: 'إعادة الفحص',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.scan,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scanMethodLabel(ExpiredUsersScanResult? result) {
    if (result == null) return 'طريقة الفحص غير متاحة';
    final version = result.versionLabel;
    final details = <String>[
      if (result.clearedProfileCount > 0) '${result.clearedProfileCount} باقة مزالة (v6)',
      if (result.stateUsedCount > 0) '${result.stateUsedCount} بحالة مستخدمة (v7)',
    ];
    return details.isEmpty ? 'معيار الراوتر: $version' : 'معيار الراوتر: $version • ${details.join(' • ')}';
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.3)),
          const SizedBox(height: 5),
          Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _optionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Obx(
            () => SwitchListTile(
              dense: true,
              value: controller.includeBytesOnly.value,
              activeColor: AppColors.info,
              title: const Text('إضافة من نفد رصيد بياناته',
                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 12)),
              subtitle: const Text('اختياري — مع بقاء مدة الاستخدام صالحة',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              onChanged: controller.setIncludeBytesOnly,
            ),
          ),
          Divider(height: 1, color: AppColors.border.withOpacity(0.8)),
          Obx(
            () => CheckboxListTile(
              dense: true,
              value: controller.isAllSelected,
              activeColor: AppColors.success,
              title: const Text('تحديد كل المؤهلين',
                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 12)),
              subtitle: Text(controller.isAllSelected ? 'اضغط لإلغاء التحديد' : 'اضغط لتحديد القائمة المعروضة',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              onChanged: (value) => controller.toggleAll(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listHeading() {
    final count = controller.displayed.length;
    return Row(
      children: [
        const Expanded(
          child: Text('المستخدمون المؤهلون',
              style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 15)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: AppColors.info.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w900, fontSize: 11)),
        ),
      ],
    );
  }

  List<Widget> _userCards() {
    final users = controller.displayed;
    if (users.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 25, 18, 23),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              Icon(Icons.verified_rounded, size: 42, color: AppColors.success),
              SizedBox(height: 10),
              Text('لا يوجد مستخدمون مؤهلون للحذف',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 13)),
              SizedBox(height: 5),
              Text('تم فحص البيانات الفعلية من الراوتر، ويمكنك السحب للأسفل لإعادة الفحص.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.45)),
            ],
          ),
        ),
      ];
    }
    return users.map(_userCard).toList();
  }

  Widget _userCard(ExpiredUserCandidate user) {
    final reasonColor = _reasonColor(user.expiredReason);
    return Obx(() {
      final selected = controller.selection[user.id] == true;
      final progress = (user.percent / 100).clamp(0.0, 1.0).toDouble();

      return Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: selected ? AppColors.info.withOpacity(0.55) : AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => controller.toggleUser(user.id, !selected),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: selected,
                    activeColor: AppColors.info,
                    onChanged: (value) => controller.toggleUser(user.id, value),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(user.username.isEmpty ? 'اسم المستخدم غير متاح' : user.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 6),
                            _badge(user.expiredReason, reasonColor),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text('${user.profile} • المستهلك ${user.usedLabel} من ${user.limitLabel}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                        if (user.customer.isNotEmpty || user.lastSeen.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            [if (user.customer.isNotEmpty) 'العميل: ${user.customer}', if (user.lastSeen.isNotEmpty) 'آخر ظهور: ${user.lastSeen}'].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(user.percent >= 100 ? AppColors.danger : AppColors.warning),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${user.percent}% من المدة'
                          '${user.usedBytes > 0 ? ' • البيانات ${user.readableUsedBytes} من ${user.readableLimitBytes}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5),
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

  Color _reasonColor(String reason) {
    return switch (reason) {
      'انتهت المدة' => AppColors.danger,
      'الباقة مُزالة (v6)' => AppColors.purple,
      'الباقة مستهلكة (v7)' => AppColors.info,
      'انتهى الرصيد' => AppColors.warning,
      _ => AppColors.textMuted,
    };
  }

  Widget _badge(String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 9)),
    );
  }

  Widget _actionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, -4))],
        ),
        child: Obx(
          () => GradientButton(
            label: controller.isDeleting.value
                ? 'جارٍ الحذف…'
                : 'حذف المحدد (${controller.selectedCount})',
            icon: Icons.delete_forever_rounded,
            height: 48,
            colors: controller.selectedCount == 0
                ? const [Color(0xFF475569), Color(0xFF64748B)]
                : const [Color(0xFF991B1B), Color(0xFFEF4444)],
            onPressed: controller.isDeleting.value || controller.selectedCount == 0
                ? null
                : controller.deleteSelected,
          ),
        ),
      ),
    );
  }
}

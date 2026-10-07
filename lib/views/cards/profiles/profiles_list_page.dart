import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/app_theme.dart';
import '../../../controllers/cards/profiles/profiles_list_controller.dart';
import '/models/profiles_model.dart';
import '../../widgets/shared/layouts/sub_page_header.dart';

class ProfilesListPage extends GetView<ProfilesListController> {
  const ProfilesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfilesListController>()) {
      Get.put(ProfilesListController());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            const PremiumHeader(
              title: 'الباقات',
              subtitle: 'إدارة باقات User Manager',
              icon: Icons.layers_rounded,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.info),
                        SizedBox(height: 12),
                        Text('جارٍ تحميل الباقات من الراوتر',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  );
                }

                if (controller.loadError.value.isNotEmpty) {
                  return _errorState(controller.loadError.value);
                }

                return RefreshIndicator(
                  onRefresh: controller.fetchPackages,
                  color: AppColors.info,
                  backgroundColor: AppColors.card,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                    children: [
                      _buildSummaryHeader(),
                      const SizedBox(height: 12),
                      _buildActionButtons(),
                      if (controller.cardCountError.value.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _warningBanner(controller.cardCountError.value),
                      ],
                      const SizedBox(height: 14),
                      if (controller.packages.isEmpty)
                        _emptyState()
                      else ...[
                        for (var index = 0; index < controller.packages.length; index++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildProfileCard(controller.packages[index], index),
                          ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _iconBadge(Icons.layers_rounded, AppColors.info),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('باقات الراوتر', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 14)),
                SizedBox(height: 3),
                Text('البيانات والأعداد معروضة من الراوتر مباشرة',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${controller.packages.length}',
                style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionButton(
                title: 'استيراد الباقات',
                icon: Icons.download_rounded,
                color: AppColors.info,
                onTap: _importPackages,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _actionButton(
                title: 'تحديث',
                icon: Icons.refresh_rounded,
                color: AppColors.textMuted,
                onTap: controller.fetchPackages,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.goToAddProfile,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة باقة'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: const Color(0xFF07111E),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _importPackages() async {
    await controller.fetchPackages();
    if (controller.loadError.value.isEmpty) {
      Get.snackbar(
        'تم التحديث',
        'تم جلب ${controller.packages.length} باقة من الراوتر',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.card,
        colorText: AppColors.text,
      );
    }
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 47),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 7),
              Flexible(
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ProfilesModel profile, int index) {
    final linkedCards = controller.linkedCardCountFor(profile.name);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _iconBadge(Icons.wifi_tethering_rounded, AppColors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      profile.customer.trim().isEmpty ? 'User Manager' : 'User Manager • ${profile.customer}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تعديل الباقة',
                onPressed: () => controller.goToEditProfile(profile),
                icon: const Icon(Icons.edit_outlined, color: AppColors.info),
              ),
              IconButton(
                tooltip: 'حذف الباقة',
                onPressed: () => controller.confirmDelete(index),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _profileTile(
                  title: 'عدد الكروت المرتبطة',
                  value: linkedCards?.toString() ?? '—',
                  icon: Icons.confirmation_number_outlined,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _profileTile(
                  title: 'السرعة',
                  value: profile.speed.trim().isEmpty ? 'غير محددة' : profile.speed,
                  icon: Icons.speed_rounded,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _profileTile(
                  title: 'السعر',
                  value: profile.price.trim().isEmpty ? 'غير محدد' : profile.price,
                  icon: Icons.payments_outlined,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _profileTile(
                  title: 'حد البيانات',
                  value: _formatDownloadLimit(profile.palance),
                  icon: Icons.download_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _profileTile(
                  title: 'الصلاحية',
                  value: _formatValidity(profile.validity),
                  icon: Icons.event_available_rounded,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _profileTile(
                  title: 'وقت الاستخدام',
                  value: _formatUptime(profile.uptime),
                  icon: Icons.access_time_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
                const SizedBox(height: 3),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.text, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(13)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _warningBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.warning, fontSize: 11), textAlign: TextAlign.center),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _iconBadge(Icons.inventory_2_outlined, AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('لا توجد باقات محفوظة على هذا الراوتر',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 5),
          const Text('استورد الباقات أو أنشئ باقة جديدة للبدء.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: controller.goToAddProfile,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إنشاء باقة'),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.warning),
            const SizedBox(height: 12),
            const Text('تعذّر تحميل الباقات',
                style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.45)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.fetchPackages,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDownloadLimit(String raw) {
    if (raw.trim().isEmpty || raw == '0') return 'غير محدود';
    try {
      final data = MikrotikDataHelper.fromString(raw);
      if (data.gigas > 0) return '${data.gigas} جيجابايت';
      if (data.megas > 0) return '${data.megas} ميجابايت';
    } catch (_) {}
    return raw;
  }

  String _formatValidity(String raw) {
    if (raw.trim().isEmpty || raw == '0') return 'غير محدد';
    final time = MikrotikTimeHelper.fromString(raw);
    if (time.days >= 30) return '${(time.days / 30).round()} شهر';
    if (time.days > 0) return '${time.days} يوم';
    if (time.hours > 0) return '${time.hours} ساعة';
    return raw;
  }

  String _formatUptime(String raw) {
    if (raw.trim().isEmpty || raw == '0') return 'غير محدد';
    final time = MikrotikTimeHelper.fromString(raw);
    final totalHours = (time.days * 24) + time.hours;
    if (totalHours > 0) return '$totalHours ساعة';
    return raw;
  }
}

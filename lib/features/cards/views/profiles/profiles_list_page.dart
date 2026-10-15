import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:mikronet/features/cards/controllers/profiles/profiles_list_controller.dart';
import 'package:mikronet/features/cards/models/profiles_model.dart';

class ProfilesListPage extends GetView<ProfilesListController> {
  const ProfilesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfilesListController>()) {
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Column(
            children: [
              // 1. شريط التطبيق العلوي (MkCards)
              PremiumHeader(title: "MkCards", subtitle: "إدارة باقات الكروت", goBack: Get.back),

              // 2. المحتوى الرئيسي القابل للتمرير
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // كارد عنوان الباقات
                      _buildHeaderCard(),
                      const SizedBox(height: 12),

                      // الأزرار الثلاثة العلوية باللون الأزرق الفاتح / Cyan
                      _buildActionButtons(controller),
                      const SizedBox(height: 14),

                      // قائمة كروت الباقات
                      Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(color: AppColors.cyan),
                            ),
                          );
                        }

                        if (controller.packages.isEmpty) {
                          // عرض باقات تجريبية نموذجية متطابقة مع الصورة
                          return Column(
                            children: [
                              _buildProfileCard(
                                name: "250",
                                price: "250",
                                template: "250",
                                linkedCards: "2550",
                                downloadLimit: "1100 ميجابايت",
                                validity: "11 ايام",
                                timeLimit: "13 ساعات",
                                onEdit: () {},
                                onDelete: () {},
                              ),
                              const SizedBox(height: 12),
                              _buildProfileCard(
                                name: "2000",
                                price: "2500",
                                template: "2000",
                                linkedCards: "1",
                                downloadLimit: "11 جيجابايت",
                                validity: "1 شهر",
                                timeLimit: "720 ساعات",
                                onEdit: () {},
                                onDelete: () {},
                              ),
                              const SizedBox(height: 12),
                              _buildProfileCard(
                                name: "200",
                                price: "200",
                                template: "200",
                                linkedCards: "2550",
                                downloadLimit: "900 ميجابايت",
                                validity: "9 ايام",
                                timeLimit: "11 ساعات",
                                onEdit: () {},
                                onDelete: () {},
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: controller.packages.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final p = entry.value;

                            final download = _formatDownloadLimit(p.palance);
                            final valid = _formatValidity(p.validity);
                            final uptime = _formatUptime(p.uptime);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildProfileCard(
                                name: p.name,
                                price: p.price,
                                template: p.name,
                                linkedCards: "1",
                                downloadLimit: download,
                                validity: valid,
                                timeLimit: uptime,
                                onEdit: () => controller.goToEditProfile(p),
                                onDelete: () => controller.confirmDelete(idx),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ================= 1. شريط التطبيق العلوي ================= */

  /* ================= 2. كارد عنوان الباقات ================= */
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panel, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.deepCyan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.layers_rounded, color: AppColors.cyan, size: 22),
          ),
          const SizedBox(width: 10),
          const Text(
            "الباقات",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /* ================= 3. الأزرار الثلاثة العلوية ================= */
  Widget _buildActionButtons(ProfilesListController controller) {
    return Column(
      children: [
        // زر استيراد باقات اليوزgroup/اليوزمنجر
        _cyanButton(
          title: "استيراد باقات اليوزgroup/اليوزمنجر",
          icon: Icons.download_rounded,
          onTap: () {
            controller.fetchPackages();
            Get.snackbar(
              "استيراد الباقات",
              "تم جلب ومزامنة باقات اليوزر مانجر من الراوتر بنجاح",
              backgroundColor: AppColors.cyan,
              colorText: AppColors.ink,
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
        const SizedBox(height: 8),

        // زر تحديث
        _cyanButton(
          title: "تحديث",
          icon: Icons.refresh_rounded,
          onTap: () => controller.fetchPackages(),
        ),
        const SizedBox(height: 8),

        // زر إضافة باقة
        _cyanButton(
          title: "إضافة باقة",
          icon: Icons.add_rounded,
          onTap: () => controller.goToAddProfile(),
        ),
      ],
    );
  }

  Widget _cyanButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.cyan,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.ink, size: 18),
          ],
        ),
      ),
    );
  }

  /* ================= 4. كارد تفاصيل الباقة ================= */
  Widget _buildProfileCard({
    required String name,
    required String price,
    required String template,
    required String linkedCards,
    required String downloadLimit,
    required String validity,
    required String timeLimit,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panel, width: 1),
      ),
      child: Column(
        children: [
          // رأس كارد الباقة (اسم الباقة + User Manager + أيقونات التعديل والحذف)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الأيقونات في اليسار (حذف + تعديل)
              Row(
                children: [
                  InkWell(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: onEdit,
                    child: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                  ),
                ],
              ),
              // معلومات الباقة في اليمين
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "User Manager",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.deepCyan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.wifi_tethering_rounded, color: AppColors.cyan, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // الصف 1: قالب الطباعة | عدد الكروت المرتبطة
          Row(
            children: [
              Expanded(
                child: _profileTile(
                  text: "$template قالب الطباعة",
                  icon: Icons.palette_outlined,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _profileTile(
                  text: "$linkedCards عدد الكروت المرتبطة",
                  icon: Icons.confirmation_number_outlined,
                  iconColor: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // الصف 2: السعر | التحميل
          Row(
            children: [
              Expanded(
                child: _profileTile(
                  text: "$price السعر",
                  icon: Icons.monetization_on_outlined,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _profileTile(
                  text: "$downloadLimit التحميل",
                  icon: Icons.download_rounded,
                  iconColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // الصف 3: الصلاحية | الوقت
          Row(
            children: [
              Expanded(
                child: _profileTile(
                  text: "$validity الصلاحية",
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _profileTile(
                  text: "$timeLimit الوقت",
                  icon: Icons.access_time_rounded,
                  iconColor: AppColors.cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileTile({
    required String text,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.panel, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 16),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDownloadLimit(String raw) {
    if (raw.isEmpty || raw == "0") return "غير محدود";
    final data = MikrotikDataHelper.fromString(raw);
    if (data.gigas > 0) return "${data.gigas} جيجابايت";
    if (data.megas > 0) return "${data.megas} ميجابايت";
    return raw;
  }

  String _formatValidity(String raw) {
    if (raw.isEmpty || raw == "0") return "غير محدد";
    final t = MikrotikTimeHelper.fromString(raw);
    if (t.days >= 30) {
      final months = (t.days / 30).round();
      return "$months شهر";
    }
    if (t.days > 0) return "${t.days} ايام";
    if (t.hours > 0) return "${t.hours} ساعات";
    return raw;
  }

  String _formatUptime(String raw) {
    if (raw.isEmpty || raw == "0") return "غير محدد";
    final t = MikrotikTimeHelper.fromString(raw);
    int totalHours = (t.days * 24) + t.hours;
    if (totalHours > 0) return "$totalHours ساعات";
    return raw;
  }
}

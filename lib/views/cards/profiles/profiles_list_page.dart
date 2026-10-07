import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cards/profiles/profiles_list_controller.dart';
import '/models/profiles_model.dart';
import '../../../core/string_extensions.dart';

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
        backgroundColor: const Color(0xFF070F1E),
        body: SafeArea(
          child: Column(
            children: [
              // 1. شريط التطبيق العلوي (MkCards)
              _buildTopAppBar(),

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
                              child: CircularProgressIndicator(color: Color(0xFF38E5FF)),
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
  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF070F1E),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _topIconBtn(Icons.language_rounded, () {}),
              const SizedBox(width: 8),
              _topIconBtn(Icons.wb_sunny_outlined, () {}),
              const SizedBox(width: 8),
              _topIconBtn(Icons.logout_rounded, () {}),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "MkCards",
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          _topIconBtn(Icons.arrow_forward_rounded, () => Get.back()),
        ],
      ),
    );
  }

  Widget _topIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E293B), width: 1),
        ),
        child: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
      ),
    );
  }

  /* ================= 2. كارد عنوان الباقات ================= */
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3B4C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.layers_rounded, color: Color(0xFF38E5FF), size: 22),
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
              backgroundColor: const Color(0xFF38E5FF),
              colorText: const Color(0xFF070F1E),
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
          color: const Color(0xFF38E5FF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38E5FF).withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF070F1E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: const Color(0xFF070F1E), size: 18),
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
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
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
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: onEdit,
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 20),
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
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3B4C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF38E5FF), size: 20),
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
                  iconColor: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _profileTile(
                  text: "$linkedCards عدد الكروت المرتبطة",
                  icon: Icons.confirmation_number_outlined,
                  iconColor: const Color(0xFF38E5FF),
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
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _profileTile(
                  text: "$downloadLimit التحميل",
                  icon: Icons.download_rounded,
                  iconColor: const Color(0xFF22C55E),
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
                  iconColor: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _profileTile(
                  text: "$timeLimit الوقت",
                  icon: Icons.access_time_rounded,
                  iconColor: const Color(0xFF38E5FF),
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
        color: const Color(0xFF131D2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2E44), width: 0.8),
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/hotspot/hotspot_controller.dart';
import '../../services/hotspot_logic.dart';
import '../widgets/shared/layouts/gradient_button.dart';
import '../widgets/shared/layouts/sub_page_header.dart';

/// صفحة **Hotspot** الكاملة: المستخدمون (القسائم) · الجلسات النشطة · الباقات ·
/// الخوادم · صفحة الدخول (رفع HTML إلى الراوتر).
class HotspotPage extends GetView<HotspotController> {
  const HotspotPage({super.key});

  static const _navy = Color(0xFF0F172A);
  static const _blue = Color(0xFF1E3A8A);
  static const _primary = Color(0xFF2563EB);
  static const _green = Color(0xFF16A34A);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFDC2626);
  static const _slate = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: "Hotspot",
              subtitle: "قسائم الإنترنت · الجلسات · الباقات · صفحة الدخول",
              icon: Icons.wifi_rounded,
              goBack: Get.back,
            ),
            TabBar(
              controller: controller.tabController,
              isScrollable: true,
              labelColor: _blue,
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: _primary,
              tabs: const [
                Tab(text: "المستخدمون"),
                Tab(text: "الجلسات"),
                Tab(text: "الباقات"),
                Tab(text: "الخوادم"),
                Tab(text: "صفحة الدخول"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: [
                  _usersTab(),
                  _sessionsTab(),
                  _profilesTab(),
                  _serversTab(),
                  _loginPageTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // ========================== المستخدمون ==========================
  // ===================================================================

  Widget _usersTab() {
    return Obx(() {
      final summary = controller.usersSummary;
      final list = controller.filteredUsers;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                _summaryStrip(summary),
                const SizedBox(height: 12),
                _searchField(
                  controller: controller.usersSearchCtrl,
                  hint: "ابحث بالاسم أو الباقة أو الملاحظة...",
                  onChanged: controller.setUsersQuery,
                ),
                const SizedBox(height: 10),
                _actionsRow(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loadingOrError(
              isLoading: controller.isLoadingUsers.value,
              error: controller.usersError.value,
              onRetry: controller.loadUsers,
              isEmpty: list.isEmpty,
              emptyMessage: controller.usersSearchCtrl.text.isEmpty
                  ? "لا يوجد مستخدمو Hotspot على هذا الراوتر"
                  : "لا نتائج مطابقة للبحث",
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, index) => _userCard(list[index]),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _summaryStrip(Map<String, int> summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _blue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _stat("الإجمالي", summary["total"] ?? 0, Colors.white),
          _stat("فعال", summary["active"] ?? 0, const Color(0xFF4ADE80)),
          _stat("قارب على الانتهاء", summary["near"] ?? 0, const Color(0xFFFCD34D)),
          _stat("منتهي", summary["exhausted"] ?? 0, const Color(0xFFFCA5A5)),
          _stat("معطّل", summary["disabled"] ?? 0, Colors.white70),
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
            style: const TextStyle(color: Colors.white70, fontSize: 9.5),
          ),
          const SizedBox(height: 4),
          Text(
            "$value",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _actionsRow() {
    return Obx(() {
      final selected = controller.selectedUsersCount;
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: "توليد قسائم",
                  icon: Icons.auto_awesome_rounded,
                  onPressed: controller.isGenerating.value ? null : () => _showVoucherDialog(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddUserDialog(),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text("مستخدم", style: TextStyle(fontSize: 13)),
                  style: _outlinedStyle(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.refreshAll,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text("تحديث", style: TextStyle(fontSize: 13)),
                  style: _outlinedStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selected == 0 ? null : () => controller.setSelectedEnabled(enabled: true),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text("تفعيل ($selected)", style: const TextStyle(fontSize: 12.5)),
                  style: _outlinedStyle(color: _green),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selected == 0 ? null : () => controller.setSelectedEnabled(enabled: false),
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  label: Text("تعطيل ($selected)", style: const TextStyle(fontSize: 12.5)),
                  style: _outlinedStyle(color: _amber),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selected == 0 ? null : controller.deleteSelectedUsers,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text("حذف ($selected)", style: const TextStyle(fontSize: 12.5)),
                  style: _outlinedStyle(color: _red),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _userCard(HotspotUser user) {
    return Obx(() {
      final selected = controller.userSelection[user.id] == true;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _primary.withOpacity(0.55) : const Color(0xFFE2E8F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                activeColor: _primary,
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
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _navy,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _chip(user.stateLabel, _userStateColor(user)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "الباقة: ${user.profile} • كلمة المرور: ${user.password.isEmpty ? '—' : user.password}",
                      style: const TextStyle(color: _slate, fontSize: 11.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "المستهلك: ${user.usedLabel} من ${user.limitLabel} "
                      "(${user.hasUptimeLimit ? '${user.uptimePercent}%' : '—'}) • "
                      "المتبقي: ${user.remainingLabel}",
                      style: const TextStyle(color: _slate, fontSize: 11.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "البيانات: ${user.bytesLabel} من ${user.limitBytesLabel}",
                      style: const TextStyle(color: _slate, fontSize: 11.5),
                    ),
                    if (user.macAddress.isNotEmpty || user.comment.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (user.macAddress.isNotEmpty) "MAC: ${user.macAddress}",
                          if (user.comment.isNotEmpty) user.comment,
                        ].join(' • '),
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Color _userStateColor(HotspotUser user) {
    if (user.disabled) return _slate;
    if (user.isExhausted) return _red;
    if (user.isNearExpiry()) return _amber;
    return _green;
  }

  // ===================================================================
  // ========================== الجلسات ==========================
  // ===================================================================

  Widget _sessionsTab() {
    return Obx(() {
      final list = controller.sessions;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "المتصلون الآن: ${list.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 14),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: controller.loadSessions,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text("تحديث", style: TextStyle(fontSize: 12.5)),
                  style: _outlinedStyle(),
                ),
                const SizedBox(width: 8),
                Obx(() => OutlinedButton.icon(
                      onPressed: controller.selectedSessions.isEmpty
                          ? null
                          : controller.disconnectSelectedSessions,
                      icon: const Icon(Icons.link_off_rounded, size: 17),
                      label: Text(
                        "قطع (${controller.selectedSessions.length})",
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      style: _outlinedStyle(color: _red),
                    )),
              ],
            ),
          ),
          Expanded(
            child: _loadingOrError(
              isLoading: controller.isLoadingSessions.value,
              error: controller.sessionsError.value,
              onRetry: controller.loadSessions,
              isEmpty: list.isEmpty,
              emptyMessage: "لا يوجد متصلون حاليًا",
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final session = list[index];
                  return Obx(() {
                    final selected = controller.sessionSelection[session.id] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? _primary.withOpacity(0.55) : const Color(0xFFE2E8F0),
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: selected,
                        activeColor: _primary,
                        onChanged: (value) => controller.toggleSession(session.id, value),
                        title: Text(
                          session.user,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 13.5),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "IP: ${session.address} • المدة: ${session.uptimeLabel}\n"
                            "الاستهلاك: ${session.usedLabel} • الدخول: ${session.loginByLabel}"
                            "${session.macAddress.isNotEmpty ? '\nMAC: ${session.macAddress}' : ''}",
                            style: const TextStyle(color: _slate, fontSize: 11, height: 1.6),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  });
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  // ===================================================================
  // ========================== الباقات ==========================
  // ===================================================================

  Widget _profilesTab() {
    return Obx(() {
      final list = controller.profiles;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "باقات المستخدمين: ${list.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 14),
                  ),
                ),
                GradientButton(
                  label: "باقة جديدة",
                  icon: Icons.add_rounded,
                  width: 150,
                  height: 42,
                  onPressed: () => _showAddProfileDialog(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingOrError(
              isLoading: controller.isLoadingProfiles.value,
              error: controller.profilesError.value,
              onRetry: controller.loadProfiles,
              isEmpty: list.isEmpty,
              emptyMessage: "لا توجد باقات Hotspot",
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final profile = list[index];
                  return _infoCard(
                    title: profile.name,
                    color: _primary,
                    lines: [
                      "المستخدمون المشتركون: ${profile.sharedUsers.isEmpty ? '1' : profile.sharedUsers}",
                      "تحديد السرعة: ${profile.rateLabel}",
                      if (profile.sessionTimeout.isNotEmpty)
                        "مدة الجلسة: ${profile.sessionTimeout}",
                      if (profile.idleTimeout.isNotEmpty) "مهلة الخمول: ${profile.idleTimeout}",
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  // ===================================================================
  // ========================== الخوادم ==========================
  // ===================================================================

  Widget _serversTab() {
    return Obx(() {
      final list = controller.servers;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "خوادم Hotspot: ${list.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 14),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: controller.loadServers,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text("تحديث", style: TextStyle(fontSize: 12.5)),
                  style: _outlinedStyle(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingOrError(
              isLoading: controller.isLoadingServers.value,
              error: controller.serversError.value,
              onRetry: controller.loadServers,
              isEmpty: list.isEmpty,
              emptyMessage: "لا يوجد خادم Hotspot مُعرَّف على الراوتر",
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final server = list[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                server.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _navy,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            _chip(server.disabled ? "معطّل" : "يعمل", server.disabled ? _slate : _green),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "المنفذ: ${server.interfaceName} • الباقة: ${server.profile}\n"
                          "مجلد صفحة الدخول: ${server.effectiveHtmlDirectory}"
                          "${server.dnsName.isNotEmpty ? '\nDNS: ${server.dnsName}' : ''}",
                          style: const TextStyle(color: _slate, fontSize: 11.5, height: 1.7),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _showSetDirectoryDialog(server),
                          icon: const Icon(Icons.folder_open_rounded, size: 17),
                          label: const Text("تغيير مجلد صفحة الدخول", style: TextStyle(fontSize: 12)),
                          style: _outlinedStyle(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  // ===================================================================
  // ========================== صفحة الدخول ==========================
  // ===================================================================

  Widget _loginPageTab() {
    return Obx(() {
      final files = controller.loginFiles;
      final issues = controller.loginIssues;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "رفع صفحة دخول Hotspot",
                  style: TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  "اختر ملفات الصفحة (يجب أن تحتوي login.html) وسيتم رفعها إلى ذاكرة الراوتر عبر FTP، "
                  "ثم يتولّى الراوتر عرضها للمتصلين.",
                  style: TextStyle(color: _slate, fontSize: 11.5, height: 1.7),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: "اختيار ملفات",
                        icon: Icons.upload_file_rounded,
                        onPressed: controller.pickLoginFiles,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (files.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.clearLoginFiles,
                          icon: const Icon(Icons.clear_all_rounded, size: 18),
                          label: const Text("تفريغ", style: TextStyle(fontSize: 12.5)),
                          style: _outlinedStyle(color: _red),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.loginDirectoryCtrl,
                  decoration: _inputDecoration(
                    "مجلد صفحة الدخول في الراوتر",
                    Icons.folder_rounded,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "الافتراضي hotspot — وتأكد من تفعيل خدمة FTP: /ip service enable ftp",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                ),
              ],
            ),
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "الملفات المختارة (${files.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  ...files.map(
                    (file) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            file.isHtml ? Icons.html_rounded : Icons.insert_drive_file_rounded,
                            size: 18,
                            color: file.isHtml ? _primary : _slate,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${file.fileName} — ${HotspotUser.readableBytes(file.effectiveSize)}",
                              style: const TextStyle(color: _navy, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: _red),
                            onPressed: () => controller.removeLoginFile(file.fileName),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "فحص الصفحة",
                    style: TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  ...issues.map(_issueRow),
                ],
              ),
            ),
          ],
          if (files.isNotEmpty) ...[
            const SizedBox(height: 14),
            GradientButton(
              label: controller.isUploadingLogin.value
                  ? "جاري الرفع... (${controller.uploadProgress.value}/${controller.uploadTotal.value})"
                  : "رفع الصفحة إلى الراوتر",
              icon: Icons.cloud_upload_rounded,
              onPressed: controller.isUploadingLogin.value ? null : controller.uploadLoginPage,
            ),
          ],
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _issueRow(LoginPageIssue issue) {
    final color = switch (issue.severity) {
      LoginIssueSeverity.error => _red,
      LoginIssueSeverity.warning => _amber,
      LoginIssueSeverity.info => _green,
    };
    final icon = switch (issue.severity) {
      LoginIssueSeverity.error => Icons.error_rounded,
      LoginIssueSeverity.warning => Icons.warning_amber_rounded,
      LoginIssueSeverity.info => Icons.check_circle_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "[${issue.label}] ${issue.message}",
              style: TextStyle(color: color, fontSize: 11.5, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // ========================== النوافذ ==========================
  // ===================================================================

  Future<void> _showAddUserDialog() async {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final profileCtrl = TextEditingController(text: "default");
    final serverCtrl = TextEditingController(text: "all");
    final uptimeCtrl = TextEditingController();
    final bytesCtrl = TextEditingController();
    final macCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    await Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text("إضافة مستخدم Hotspot", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, "اسم المستخدم *", Icons.person_rounded),
                _dialogField(passCtrl, "كلمة المرور", Icons.lock_rounded),
                _dialogField(profileCtrl, "الباقة (profile)", Icons.card_membership_rounded),
                _dialogField(serverCtrl, "الخادم (server)", Icons.dns_rounded),
                _dialogField(uptimeCtrl, "مدة الصلاحية (مثال: 1d · 12h · 1w2d)", Icons.timer_rounded),
                _dialogField(bytesCtrl, "حد البيانات (مثال: 500M · 2G)", Icons.data_usage_rounded),
                _dialogField(macCtrl, "ربط بـ MAC (اختياري)", Icons.memory_rounded),
                _dialogField(commentCtrl, "ملاحظة", Icons.notes_rounded),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              onPressed: () async {
                Get.back();
                await controller.addUser(
                  name: nameCtrl.text,
                  password: passCtrl.text,
                  profile: profileCtrl.text.trim().isEmpty ? "default" : profileCtrl.text.trim(),
                  server: serverCtrl.text.trim().isEmpty ? "all" : serverCtrl.text.trim(),
                  limitUptime: uptimeCtrl.text,
                  limitBytes: bytesCtrl.text,
                  macAddress: macCtrl.text,
                  comment: commentCtrl.text,
                );
              },
              child: const Text("إضافة", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVoucherDialog() async {
    final countCtrl = TextEditingController(text: "10");
    final userLenCtrl = TextEditingController(text: "8");
    final passLenCtrl = TextEditingController(text: "6");
    final prefixCtrl = TextEditingController();
    final profileCtrl = TextEditingController(text: "default");
    final uptimeCtrl = TextEditingController(text: "1d");
    final bytesCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    var charset = VoucherCharset.digits;

    await Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Text("توليد قسائم Hotspot", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(countCtrl, "عدد القسائم (1 - 1000)", Icons.numbers_rounded, isNumber: true),
                  Row(
                    children: [
                      Expanded(child: _dialogField(userLenCtrl, "طول الاسم", Icons.badge_rounded, isNumber: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _dialogField(passLenCtrl, "طول كلمة المرور", Icons.password_rounded, isNumber: true)),
                    ],
                  ),
                  _dialogField(prefixCtrl, "بادئة الاسم (اختياري)", Icons.tag_rounded),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<VoucherCharset>(
                    value: charset,
                    decoration: _inputDecoration("نوع الأحرف", Icons.text_fields_rounded),
                    items: VoucherCharset.values
                        .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                        .toList(),
                    onChanged: (value) => setState(() => charset = value ?? VoucherCharset.digits),
                  ),
                  const SizedBox(height: 10),
                  _dialogField(profileCtrl, "الباقة (profile)", Icons.card_membership_rounded),
                  _dialogField(uptimeCtrl, "مدة الصلاحية (1d · 12h · 1w2d)", Icons.timer_rounded),
                  _dialogField(bytesCtrl, "حد البيانات (500M · 2G — اختياري)", Icons.data_usage_rounded),
                  _dialogField(commentCtrl, "ملاحظة على القسائم", Icons.notes_rounded),
                  const SizedBox(height: 6),
                  const Text(
                    "تُستثنى الأحرف الملتبسة (0/O و 1/I) تلقائيًا لسهولة القراءة.",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: Get.back, child: const Text("إلغاء")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _blue),
                onPressed: () async {
                  final spec = VoucherSpec(
                    count: int.tryParse(countCtrl.text.trim()) ?? 0,
                    usernameLength: int.tryParse(userLenCtrl.text.trim()) ?? 8,
                    passwordLength: int.tryParse(passLenCtrl.text.trim()) ?? 6,
                    charset: charset,
                    prefix: prefixCtrl.text.trim(),
                    profile: profileCtrl.text.trim().isEmpty ? "default" : profileCtrl.text.trim(),
                    limitUptime: uptimeCtrl.text.trim(),
                    limitBytes: bytesCtrl.text.trim(),
                    comment: commentCtrl.text.trim(),
                  );

                  final issues = spec.validate();
                  if (issues.isNotEmpty) {
                    Get.back();
                    await controller.generateVouchers(spec);
                    return;
                  }

                  Get.back();
                  final added = await controller.generateVouchers(spec);
                  if (added > 0) setState(() {});
                },
                child: const Text("توليد", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );

    // بعد الإغلاق: إن وُجدت قسائم، اعرض خيارات الطباعة/التصدير
    if (controller.lastVouchers.isNotEmpty) {
      await _showVoucherResultDialog();
    }
  }

  Future<void> _showVoucherResultDialog() async {
    await Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            "تم توليد ${controller.lastVouchers.length} قسيمة",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          content: const Text(
            "يمكنك الآن طباعة القسائم كملف PDF جاهز للقص، أو تصديرها كملف CSV لبرنامج Excel.",
            style: TextStyle(color: _slate, fontSize: 12.5, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                controller.exportVouchersCsv();
              },
              child: const Text("تصدير CSV"),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                controller.exportVouchersPdf();
              },
              child: const Text("طباعة PDF"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              onPressed: Get.back,
              child: const Text("إغلاق", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProfileDialog() async {
    final nameCtrl = TextEditingController();
    final sharedCtrl = TextEditingController(text: "1");
    final rateCtrl = TextEditingController();
    final timeoutCtrl = TextEditingController();

    await Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text("باقة Hotspot جديدة", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, "اسم الباقة *", Icons.card_membership_rounded),
                _dialogField(sharedCtrl, "عدد المستخدمين المشتركين", Icons.group_rounded, isNumber: true),
                _dialogField(rateCtrl, "تحديد السرعة (مثال: 2M/2M)", Icons.speed_rounded),
                _dialogField(timeoutCtrl, "مدة الجلسة (مثال: 8h)", Icons.timer_rounded),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              onPressed: () async {
                Get.back();
                await controller.addProfile(
                  name: nameCtrl.text,
                  sharedUsers: sharedCtrl.text.trim().isEmpty ? "1" : sharedCtrl.text.trim(),
                  rateLimit: rateCtrl.text,
                  sessionTimeout: timeoutCtrl.text,
                );
              },
              child: const Text("إنشاء", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetDirectoryDialog(HotspotServer server) async {
    final dirCtrl = TextEditingController(text: server.effectiveHtmlDirectory);

    await Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text("مجلد صفحة الدخول — ${server.name}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(dirCtrl, "اسم المجلد", Icons.folder_rounded),
              const Text(
                "يجب أن يكون المجلد موجودًا في ذاكرة الراوتر وأن يحتوي login.html",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              onPressed: () {
                final directory = dirCtrl.text.trim();
                Get.back();
                controller.setServerHtmlDirectory(server, directory);
              },
              child: const Text("حفظ", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // ========================== عناصر مشتركة ==========================
  // ===================================================================

  ButtonStyle _outlinedStyle({Color color = _blue}) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size.fromHeight(42),
      side: BorderSide(color: color.withOpacity(0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _searchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: _inputDecoration(hint, Icons.search_rounded),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: _inputDecoration(label, icon),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _infoCard({
    required String title,
    required Color color,
    required List<String> lines,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_membership_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(line, style: const TextStyle(color: _slate, fontSize: 11.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _loadingOrError({
    required bool isLoading,
    required String error,
    required VoidCallback onRetry,
    required bool isEmpty,
    required String emptyMessage,
    required Widget child,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: _amber, size: 40),
              const SizedBox(height: 10),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _slate, fontSize: 12.5, height: 1.7),
              ),
              const SizedBox(height: 14),
              GradientButton(label: "إعادة المحاولة", icon: Icons.refresh_rounded, onPressed: onRetry),
            ],
          ),
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      );
    }

    return child;
  }
}

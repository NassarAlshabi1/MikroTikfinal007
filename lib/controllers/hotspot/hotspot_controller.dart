import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../api/hotspot_api.dart';
import '../../controllers/dialog_helper.dart';
import '../helpers/confirm_dialog.dart';
import '../../services/hotspot_logic.dart';
import '../../services/hotspot_pdf.dart';

/// متحكم **Hotspot** الكامل: المستخدمون (القسائم)، الجلسات النشطة، الباقات،
/// الخوادم، ورفع صفحة الدخول إلى الراوتر.
class HotspotController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  // ===================== المستخدمون =====================
  final RxList<HotspotUser> users = <HotspotUser>[].obs;
  final RxBool isLoadingUsers = true.obs;
  final RxString usersError = "".obs;
  final usersSearchCtrl = TextEditingController();
  final RxString usersQuery = "".obs;

  /// معرّف المستخدم ← مُحدد؟
  final RxMap<String, bool> userSelection = <String, bool>{}.obs;

  // ===================== الجلسات النشطة =====================
  final RxList<HotspotActiveSession> sessions = <HotspotActiveSession>[].obs;
  final RxBool isLoadingSessions = true.obs;
  final RxString sessionsError = "".obs;
  final RxMap<String, bool> sessionSelection = <String, bool>{}.obs;

  // ===================== الباقات =====================
  final RxList<HotspotProfile> profiles = <HotspotProfile>[].obs;
  final RxBool isLoadingProfiles = true.obs;
  final RxString profilesError = "".obs;

  // ===================== الخوادم =====================
  final RxList<HotspotServer> servers = <HotspotServer>[].obs;
  final RxBool isLoadingServers = true.obs;
  final RxString serversError = "".obs;

  // ===================== توليد القسائم =====================
  final RxInt voucherProgress = 0.obs;
  final RxInt voucherTotal = 0.obs;
  final RxBool isGenerating = false.obs;

  /// آخر قسائم مولّدة (للطباعة والتصدير).
  final RxList<VoucherPrintItem> lastVouchers = <VoucherPrintItem>[].obs;

  // ===================== صفحة الدخول =====================
  final RxList<HotspotLoginFile> loginFiles = <HotspotLoginFile>[].obs;
  final RxList<LoginPageIssue> loginIssues = <LoginPageIssue>[].obs;
  final RxBool isUploadingLogin = false.obs;
  final RxInt uploadProgress = 0.obs;
  final RxInt uploadTotal = 0.obs;
  final loginDirectoryCtrl = TextEditingController(text: "hotspot");

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 5, vsync: this);
    refreshAll();
  }

  /// تحديث كل البيانات (المستخدمون/الجلسات/الباقات/الخوادم).
  Future<void> refreshAll() async {
    await Future.wait([
      loadUsers(),
      loadSessions(),
      loadProfiles(),
      loadServers(),
    ]);
  }

  // ===================== تحميل البيانات =====================

  Future<void> loadUsers() async {
    isLoadingUsers.value = true;
    usersError.value = "";

    final response = await HotspotApi.printUsers();

    isLoadingUsers.value = false;

    if (!response.status) {
      users.clear();
      usersError.value = response.message;
      return;
    }

    users.assignAll(response.data ?? []);
    userSelection.removeWhere((key, _) => !users.any((user) => user.id == key));
    _applyUsersSearch();
  }

  Future<void> loadSessions() async {
    isLoadingSessions.value = true;
    sessionsError.value = "";

    final response = await HotspotApi.printActive();

    isLoadingSessions.value = false;

    if (!response.status) {
      sessions.clear();
      sessionsError.value = response.message;
      return;
    }

    sessions.assignAll(response.data ?? []);
    sessionSelection.clear();
  }

  Future<void> loadProfiles() async {
    isLoadingProfiles.value = true;
    profilesError.value = "";

    final response = await HotspotApi.printProfiles();

    isLoadingProfiles.value = false;

    if (!response.status) {
      profiles.clear();
      profilesError.value = response.message;
      return;
    }

    profiles.assignAll(response.data ?? []);
  }

  Future<void> loadServers() async {
    isLoadingServers.value = true;
    serversError.value = "";

    final response = await HotspotApi.printServers();

    isLoadingServers.value = false;

    if (!response.status) {
      servers.clear();
      serversError.value = response.message;
      return;
    }

    servers.assignAll(response.data ?? []);
  }

  // ===================== البحث والتحديد =====================

  void setUsersQuery(String query) {
    usersQuery.value = query;
    _applyUsersSearch();
  }

  /// المستخدمون المعروضون بعد البحث (الاسم/الملف/الملاحظة/العنوان).
  List<HotspotUser> get filteredUsers {
    final query = usersQuery.value.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.profile.toLowerCase().contains(query) ||
          user.comment.toLowerCase().contains(query) ||
          user.macAddress.toLowerCase().contains(query);
    }).toList();
  }

  void _applyUsersSearch() {
    // البحث محسوب في filteredUsers — لا شيء إضافي هنا
  }

  void toggleUser(String id, bool? value) => userSelection[id] = value ?? false;

  void toggleAllUsers(bool? value) {
    final flag = value ?? false;
    for (final user in filteredUsers) {
      userSelection[user.id] = flag;
    }
  }

  List<HotspotUser> get selectedUsers =>
      users.where((user) => userSelection[user.id] == true).toList();

  int get selectedUsersCount => selectedUsers.length;

  bool get isAllSelected {
    final list = filteredUsers;
    if (list.isEmpty) return false;
    return list.every((user) => userSelection[user.id] == true);
  }

  void toggleSession(String id, bool? value) => sessionSelection[id] = value ?? false;

  List<HotspotActiveSession> get selectedSessions =>
      sessions.where((session) => sessionSelection[session.id] == true).toList();

  /// ملخّص إحصائي للمستخدمين (يظهر أعلى التبويب).
  Map<String, int> get usersSummary {
    var active = 0, disabled = 0, exhausted = 0, near = 0;
    for (final user in users) {
      if (user.disabled) {
        disabled++;
      } else {
        active++;
      }
      if (user.isExhausted) exhausted++;
      if (user.isNearExpiry()) near++;
    }
    return {
      "total": users.length,
      "active": active,
      "disabled": disabled,
      "exhausted": exhausted,
      "near": near,
    };
  }

  // ===================== عمليات المستخدمين =====================

  /// إضافة مستخدم يدويًا.
  Future<bool> addUser({
    required String name,
    required String password,
    required String profile,
    String server = "all",
    String limitUptime = "",
    String limitBytes = "",
    String macAddress = "",
    String comment = "",
  }) async {
    if (name.trim().isEmpty) {
      await showMsgDialog(message: "اسم المستخدم مطلوب", type: MsgType.warning);
      return false;
    }
    if (users.any((user) => user.name == name.trim())) {
      await showMsgDialog(message: "اسم المستخدم «$name» موجود مسبقًا", type: MsgType.warning);
      return false;
    }

    showLoadingDialog(message: "جاري إضافة المستخدم...");
    final response = await HotspotApi.addUser(
      name: name.trim(),
      password: password.trim(),
      profile: profile,
      server: server,
      limitUptime: limitUptime,
      limitBytes: limitBytes,
      macAddress: macAddress,
      comment: comment,
    );
    hideDialog();

    if (!response.status) {
      await showMsgDialog(message: response.message, type: MsgType.error);
      return false;
    }

    await showMsgDialog(message: "تمت إضافة المستخدم «$name»", type: MsgType.success);
    await loadUsers();
    return true;
  }

  /// تعديل مستخدم (الحقول المُمرَّرة فقط).
  Future<void> editUser(String id, Map<String, String> data) async {
    showLoadingDialog(message: "جاري حفظ التعديلات...");
    final response = await HotspotApi.editUser(id: id, data: data);
    hideDialog();

    if (!response.status) {
      await showMsgDialog(message: response.message, type: MsgType.error);
      return;
    }
    await loadUsers();
  }

  /// تفعيل/تعطيل المحددين.
  Future<void> setSelectedEnabled({required bool enabled}) async {
    final selected = selectedUsers;
    if (selected.isEmpty) {
      await showMsgDialog(message: "لم تحدد أي مستخدم", type: MsgType.warning);
      return;
    }

    showLoadingDialog(message: enabled ? "جاري التفعيل..." : "جاري التعطيل...");
    final response = await HotspotApi.setEnabled(
      selected.map((user) => user.id).toList(),
      enabled: enabled,
    );
    hideDialog();

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    if (response.status) await loadUsers();
  }

  /// حذف المحددين (بعد تأكيد).
  Future<void> deleteSelectedUsers() async {
    final selected = selectedUsers;
    if (selected.isEmpty) {
      await showMsgDialog(message: "لم تحدد أي مستخدم للحذف", type: MsgType.warning);
      return;
    }

    final confirmed = await confirmAction(
      "سيتم حذف ${selected.length} مستخدمًا من Hotspot نهائيًا.\n"
      "لا يمكن التراجع — هل تريد المتابعة؟",
    );
    if (!confirmed) return;

    showLoadingDialog(message: "جاري الحذف...");
    final response = await HotspotApi.removeUsers(selected);
    hideDialog();

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    if (response.status) await loadUsers();
  }

  /// قطع الجلسات المحددة.
  Future<void> disconnectSelectedSessions() async {
    final selected = selectedSessions;
    if (selected.isEmpty) {
      await showMsgDialog(message: "لم تحدد أي جلسة", type: MsgType.warning);
      return;
    }

    final confirmed = await confirmAction(
      "سيتم قطع ${selected.length} جلسة وإخراج أصحابها من الشبكة فورًا. متابعة؟",
    );
    if (!confirmed) return;

    showLoadingDialog(message: "جاري قطع الجلسات...");
    final response = await HotspotApi.disconnectSessions(selected);
    hideDialog();

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    if (response.status) await loadSessions();
  }

  // ===================== توليد القسائم =====================

  /// توليد قسائم وإضافتها للراوتر. ترجع عدد المضاف.
  Future<int> generateVouchers(VoucherSpec spec) async {
    final issues = spec.validate();
    if (issues.isNotEmpty) {
      await showMsgDialog(message: issues.first, type: MsgType.warning);
      return 0;
    }

    final vouchers = HotspotVoucherGenerator.generate(spec);

    isGenerating.value = true;
    voucherProgress.value = 0;
    voucherTotal.value = vouchers.length;
    showLoadingDialog(message: "جاري توليد القسائم...");

    final response = await HotspotApi.addVouchers(
      spec: spec,
      vouchers: vouchers,
      onProgress: (done, total) => voucherProgress.value = done,
    );

    hideDialog();
    isGenerating.value = false;

    if (!response.status) {
      await showMsgDialog(message: response.message, type: MsgType.error);
      return 0;
    }

    // حفظ القسائم المضافة فقط (الفاشلة لا تُطبع)
    final failedNames = response.data?.failed.toSet() ?? <String>{};
    final validity = spec.limitUptime.trim();
    final dataLimit = spec.limitBytes.trim();
    lastVouchers.assignAll(
      vouchers
          .where((voucher) => !failedNames.contains(voucher.username))
          .map(
            (voucher) => VoucherPrintItem(
              username: voucher.username,
              password: voucher.password,
              profile: spec.profile,
              validity: validity,
              dataLimit: dataLimit,
              note: spec.comment,
            ),
          )
          .toList(),
    );

    await showMsgDialog(message: response.message, type: MsgType.success);
    await loadUsers();
    return response.data?.added ?? 0;
  }

  /// طباعة/مشاركة آخر قسائم مولّدة (PDF جاهز للقص).
  Future<void> exportVouchersPdf({String title = "MikroNet Hotspot"}) async {
    if (lastVouchers.isEmpty) {
      await showMsgDialog(message: "لا توجد قسائم للطباعة — ولّد قسائم أولًا", type: MsgType.warning);
      return;
    }

    showLoadingDialog(message: "جاري تجهيز ملف الطباعة...");
    try {
      await HotspotVoucherPdf.export(
        vouchers: lastVouchers.toList(),
        title: title,
        subtitle: "عدد القسائم: ${lastVouchers.length}",
      );
      hideDialog();
    } catch (e) {
      hideDialog();
      await showMsgDialog(message: "تعذّر إنشاء ملف الطباعة:\n$e", type: MsgType.error);
    }
  }

  /// تصدير آخر قسائم كملف CSV (Excel).
  Future<void> exportVouchersCsv() async {
    if (lastVouchers.isEmpty) {
      await showMsgDialog(message: "لا توجد قسائم للتصدير", type: MsgType.warning);
      return;
    }

    final csv = VoucherExporter.toCsv(lastVouchers.toList());
    await _saveTextFile(
      fileName: "hotspot_vouchers.csv",
      content: csv,
      mimeHint: "csv",
    );
  }

  /// حفظ نص كملف عبر نافذة النظام (استخدام file_picker للحفظ).
  Future<void> _saveTextFile({
    required String fileName,
    required String content,
    String mimeHint = "txt",
  }) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: "حفظ الملف",
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [mimeHint],
        bytes: utf8.encode(content),
      );
      if (path == null) return;
      await showMsgDialog(message: "تم حفظ الملف:\n$path", type: MsgType.success);
    } catch (e) {
      await showMsgDialog(message: "تعذّر حفظ الملف:\n$e", type: MsgType.error);
    }
  }

  // ===================== باقات =====================

  Future<void> addProfile({
    required String name,
    String sharedUsers = "1",
    String rateLimit = "",
    String sessionTimeout = "",
  }) async {
    if (name.trim().isEmpty) {
      await showMsgDialog(message: "اسم الباقة مطلوب", type: MsgType.warning);
      return;
    }

    showLoadingDialog(message: "جاري إنشاء الباقة...");
    final response = await HotspotApi.addProfile(
      name: name.trim(),
      sharedUsers: sharedUsers,
      rateLimit: rateLimit,
      sessionTimeout: sessionTimeout,
    );
    hideDialog();

    await showMsgDialog(
      message: response.status ? "تمت إضافة الباقة «$name»" : response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    if (response.status) await loadProfiles();
  }

  // ===================== خوادم =====================

  Future<void> setServerHtmlDirectory(HotspotServer server, String directory) async {
    showLoadingDialog(message: "جاري تحديث مجلد صفحة الدخول...");
    final response = await HotspotApi.setHtmlDirectory(
      serverName: server.name,
      directory: directory,
    );
    hideDialog();

    await showMsgDialog(
      message: response.status
          ? "تم تعيين مجلد صفحة الدخول للخادم «${server.name}» إلى $directory"
          : response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    if (response.status) await loadServers();
  }

  // ===================== صفحة الدخول =====================

  /// اختيار ملفات صفحة الدخول من الهاتف.
  Future<void> pickLoginFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ["html", "htm", "css", "js", "png", "jpg", "jpeg", "gif", "svg", "txt"],
      );

      if (result == null || result.files.isEmpty) return;

      final files = <HotspotLoginFile>[];
      for (final picked in result.files) {
        final bytes = picked.bytes;
        if (bytes == null) continue;
        final isText = !picked.extension
            .toString()
            .toLowerCase()
            .contains(RegExp(r'^(png|jpg|jpeg|gif)$'));
        files.add(HotspotLoginFile(
          fileName: picked.name,
          content: isText ? utf8.decode(bytes, allowMalformed: true) : "",
          bytes: bytes,
        ));
      }

      loginFiles.assignAll(files);
      loginIssues.assignAll(HotspotLoginPageValidator.validate(files));
    } catch (e) {
      await showMsgDialog(message: "تعذّر قراءة الملفات:\n$e", type: MsgType.error);
    }
  }

  void removeLoginFile(String fileName) {
    loginFiles.removeWhere((file) => file.fileName == fileName);
    loginIssues.assignAll(HotspotLoginPageValidator.validate(loginFiles.toList()));
  }

  void clearLoginFiles() {
    loginFiles.clear();
    loginIssues.clear();
  }

  bool get canUploadLoginPage =>
      loginFiles.isNotEmpty && HotspotLoginPageValidator.canUpload(loginFiles.toList());

  /// رفع الملفات المختارة إلى الراوتر عبر FTP.
  Future<void> uploadLoginPage() async {
    if (loginFiles.isEmpty) {
      await showMsgDialog(message: "اختر ملفات صفحة الدخول أولًا", type: MsgType.warning);
      return;
    }

    final issues = HotspotLoginPageValidator.validate(loginFiles.toList());
    loginIssues.assignAll(issues);

    if (issues.any((issue) => issue.severity == LoginIssueSeverity.error)) {
      await showMsgDialog(
        message: "لا يمكن الرفع قبل إصلاح الأخطاء:\n"
            "${issues.where((i) => i.severity == LoginIssueSeverity.error).map((i) => '• ${i.message}').join('\n')}",
        type: MsgType.error,
      );
      return;
    }

    final confirmed = await confirmAction(
      "سيتم رفع ${loginFiles.length} ملفًا إلى مجلد «${loginDirectoryCtrl.text}» في ذاكرة الراوتر،\n"
      "واستبدال أي ملفات بنفس الأسماء.\n\nمتابعة؟",
    );
    if (!confirmed) return;

    isUploadingLogin.value = true;
    uploadProgress.value = 0;
    uploadTotal.value = loginFiles.length;
    showLoadingDialog(message: "جاري رفع الملفات...");

    final response = await HotspotApi.uploadLoginPage(
      files: loginFiles.toList(),
      directory: loginDirectoryCtrl.text,
      onProgress: (done, total) => uploadProgress.value = done,
    );

    hideDialog();
    isUploadingLogin.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
  }

  @override
  void onClose() {
    tabController.dispose();
    usersSearchCtrl.dispose();
    loginDirectoryCtrl.dispose();
    super.onClose();
  }
}

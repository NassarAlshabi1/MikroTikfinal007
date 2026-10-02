import 'package:get/get.dart';

import '../../api/maintenance_api.dart';
import '../../services/cable_diagnostics.dart';

/// متحكم صفحة **فحص الكيبل**: يعرض منافذ الإيثرنت، يفحص أزواج الكيبل،
/// ويقرأ سرعة الاتصال الفعلية ثم يصوغ تشخيصًا وتوصيات واضحة.
class CableTestController extends GetxController {
  /// منافذ الإيثرنت كما رجعها الراوتر.
  final RxList<Map<String, String>> ports = <Map<String, String>>[].obs;

  /// المنفذ المختار حاليًا.
  final RxString selectedPort = "".obs;

  final RxBool isLoadingPorts = true.obs;
  final RxBool isTestingCable = false.obs;
  final RxBool isReadingLink = false.obs;

  final RxString errorMessage = "".obs;

  final Rx<CableTestResult?> cableResult = Rx<CableTestResult?>(null);
  final Rx<EthernetLinkInfo?> linkInfo = Rx<EthernetLinkInfo?>(null);
  final Rx<CableDiagnosis?> diagnosis = Rx<CableDiagnosis?>(null);

  bool get isBusy => isTestingCable.value || isReadingLink.value;

  @override
  void onInit() {
    super.onInit();
    loadPorts();
  }

  /// قراءة منافذ الإيثرنت واختيار أول منفذ تلقائيًا.
  Future<void> loadPorts() async {
    isLoadingPorts.value = true;
    errorMessage.value = "";

    final response = await MaintenanceApi.ethernetPorts();

    isLoadingPorts.value = false;

    if (!response.status || response.data == null || response.data!.isEmpty) {
      ports.clear();
      errorMessage.value = response.message.isEmpty
          ? "تعذّر قراءة منافذ الإيثرنت من الراوتر"
          : response.message;
      return;
    }

    ports.assignAll(response.data!);

    final current = selectedPort.value;
    final stillExists = ports.any((port) => portName(port) == current);
    if (!stillExists) {
      selectedPort.value = portName(ports.first);
    }
  }

  /// اسم المنفذ من صف الراوتر.
  static String portName(Map<String, String> port) {
    final name = port["name"] ?? "";
    if (name.isNotEmpty) return name;
    return port["default-name"] ?? "—";
  }

  /// هل المنفذ يعمل الآن؟ (running=true و disabled غير مفعّل)
  static bool portUp(Map<String, String> port) {
    final running = (port["running"] ?? "").toLowerCase();
    final disabled = (port["disabled"] ?? "").toLowerCase();
    if (disabled == "true" || disabled == "yes") return false;
    return running == "true" || running == "yes";
  }

  /// شرح مختصر للمنفذ (الحالة + ملاحظة المستخدم).
  static String portSubtitle(Map<String, String> port) {
    final parts = <String>[];
    if ((port["slave"] ?? "").toLowerCase() == "true") parts.add("تابع لسويتش");
    if ((port["switch"] ?? "").isNotEmpty) parts.add("سويتش: ${port["switch"]}");
    final comment = (port["comment"] ?? "").trim();
    if (comment.isNotEmpty) parts.add(comment);
    return parts.join(" • ");
  }

  void selectPort(String name) {
    if (name == selectedPort.value) return;
    selectedPort.value = name;
    // نتائج المنفذ السابق لا تنطبق على منفذ آخر
    cableResult.value = null;
    linkInfo.value = null;
    diagnosis.value = null;
    errorMessage.value = "";
  }

  /// الفحص الكامل: أزواج الكيبل + سرعة الاتصال + التشخيص.
  Future<void> runFullTest() async {
    await _runCableTest();
    if (!isTestingCable.value && cableResult.value != null) {
      await _readLink();
    }
  }

  /// فحص الأزواج فقط.
  Future<void> runCableTestOnly() => _runCableTest();

  /// قراءة السرعة فقط.
  Future<void> readLinkOnly() => _readLink();

  Future<void> _runCableTest() async {
    final port = selectedPort.value;
    if (port.isEmpty) return;

    isTestingCable.value = true;
    errorMessage.value = "";

    final response = await MaintenanceApi.cableTest(interfaceName: port);

    isTestingCable.value = false;

    if (response.status && response.data != null) {
      cableResult.value = CableTestResult.parse(interfaceName: port, rows: response.data!);
    } else {
      cableResult.value = CableTestResult.unsupported(port, response.message);
    }

    _rebuildDiagnosis();
  }

  Future<void> _readLink() async {
    final port = selectedPort.value;
    if (port.isEmpty) return;

    isReadingLink.value = true;

    final response = await MaintenanceApi.ethernetMonitor(interfaceName: port);

    isReadingLink.value = false;

    if (response.status && response.data != null) {
      linkInfo.value = response.data;
    } else {
      // قراءة السرعة مكمّلة للفحص — لا نُفشل الصفحة إن لم تُدعم
      errorMessage.value = response.message;
    }

    _rebuildDiagnosis();
  }

  void _rebuildDiagnosis() {
    diagnosis.value = CableDiagnostics.combine(
      cable: cableResult.value,
      link: linkInfo.value,
    );
  }
}

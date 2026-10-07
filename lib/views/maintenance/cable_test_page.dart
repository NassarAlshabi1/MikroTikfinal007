import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/maintenance/cable_test_controller.dart';
import '../../services/cable_diagnostics.dart';
import '../widgets/shared/layouts/gradient_button.dart';
import '../widgets/shared/layouts/sub_page_header.dart';

/// صفحة **فحص الكيبل**: اختيار منفذ الإيثرنت، فحص الأزواج الأربعة،
/// قراءة السرعة الفعلية، وعرض تشخيص عربي مع توصيات عملية.
class CableTestPage extends GetView<CableTestController> {
  const CableTestPage({super.key});

  // ألوان الحالات (موحّدة مع هوية التطبيق)
  static const _navy = Color(0xFF0F172A);
  static const _blue = Color(0xFF3B82F6);
  static const _primary = Color(0xFF2563EB);
  static const _green = Color(0xFF16A34A);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFDC2626);
  static const _slate = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Column(
          children: [
            PremiumHeader(
              title: "فحص الكيبل",
              subtitle: "اختبار أزواج الكيبل وسرعة الاتصال الفعلية",
              icon: Icons.cable_rounded,
              goBack: Get.back,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _portsCard(),
                  const SizedBox(height: 14),
                  _actionsCard(),
                  const SizedBox(height: 14),
                  _cableResultSection(),
                  _linkSection(),
                  _diagnosisSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== اختيار المنفذ =====================

  Widget _portsCard() {
    return Obx(() {
      if (controller.isLoadingPorts.value) {
        return _card(
          child: const Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text("جاري قراءة منافذ الإيثرنت...", style: TextStyle(color: _slate)),
            ],
          ),
        );
      }

      if (controller.ports.isEmpty) {
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: _amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "تعذّر قراءة منافذ الإيثرنت",
                      style: TextStyle(fontWeight: FontWeight.bold, color: _navy),
                    ),
                  ),
                ],
              ),
              if (controller.errorMessage.value.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: _slate, fontSize: 12, height: 1.6),
                ),
              ],
              const SizedBox(height: 12),
              GradientButton(
                label: "إعادة المحاولة",
                icon: Icons.refresh_rounded,
                onPressed: controller.loadPorts,
              ),
            ],
          ),
        );
      }

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "اختر منفذ الإيثرنت",
              style: TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.ports.map((port) {
                final name = CableTestController.portName(port);
                final selected = name == controller.selectedPort.value;
                final up = CableTestController.portUp(port);
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => controller.selectPort(name),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: up ? _green : _slate,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(name),
                    ],
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : _navy,
                  ),
                  selectedColor: _blue,
                  backgroundColor: const Color(0xFF1B2740),
                  side: BorderSide(
                    color: selected ? _blue : const Color(0xFF243352),
                  ),
                );
              }).toList(),
            ),
            if (_selectedPortSubtitle().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _selectedPortSubtitle(),
                style: const TextStyle(color: _slate, fontSize: 11.5),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _selectedPortSubtitle() {
    final port = controller.ports.firstWhere(
      (element) => CableTestController.portName(element) == controller.selectedPort.value,
      orElse: () => <String, String>{},
    );
    if (port.isEmpty) return "";
    final subtitle = CableTestController.portSubtitle(port);
    final up = CableTestController.portUp(port);
    final status = up ? "المنفذ يعمل الآن" : "المنفذ غير متصل";
    return subtitle.isEmpty ? status : "$status • $subtitle";
  }

  // ===================== أزرار الفحص =====================

  Widget _actionsCard() {
    return Obx(() {
      final busy = controller.isBusy;
      return Row(
        children: [
          Expanded(
            child: GradientButton(
              label: controller.isTestingCable.value ? "جاري فحص الكيبل..." : "فحص الكيبل",
              icon: Icons.cable_rounded,
              onPressed: busy ? null : controller.runFullTest,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : controller.readLinkOnly,
              icon: controller.isReadingLink.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.speed_rounded, size: 18),
              label: const Text("قراءة السرعة", style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                minimumSize: const Size.fromHeight(45),
                side: BorderSide(color: _blue.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ===================== نتيجة فحص الأزواج =====================

  Widget _cableResultSection() {
    return Obx(() {
      final result = controller.cableResult.value;
      if (result == null) return const SizedBox.shrink();

      final color = _severityColor(result.severity);

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_severityIcon(result.severity), color: color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "نتيجة فحص ${result.interfaceName}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 14),
                    ),
                  ),
                  _chip(result.supported ? result.severity.severityLabel : "غير مدعوم", color),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                result.summary,
                style: const TextStyle(color: _slate, fontSize: 12.5, height: 1.6),
              ),
              if (result.pairs.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...result.pairs.map(_pairRow),
              ],
              if (result.rawPairs.isNotEmpty) ...[
                const SizedBox(height: 10),
                _rawLine("قراءة الراوتر الخام: ${result.rawPairs}"),
              ],
              if (!result.supported && result.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  result.errorMessage,
                  style: const TextStyle(color: _amber, fontSize: 12, height: 1.6),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _pairRow(CablePairResult pair) {
    final color = _pairColor(pair.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Text(
              "${pair.index}",
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "الزوج ${pair.index} — ${pair.label}",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  pair.description,
                  style: const TextStyle(color: _slate, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
          Icon(
            pair.isOk ? Icons.check_circle_rounded : Icons.error_rounded,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ===================== معلومات الاتصال =====================

  Widget _linkSection() {
    return Obx(() {
      final link = controller.linkInfo.value;
      if (link == null) return const SizedBox.shrink();

      final degraded = link.isDegraded;
      final color = !link.hasLink
          ? _slate
          : degraded
              ? _amber
              : _green;

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.speed_rounded, color: color, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "سرعة الاتصال الفعلية",
                      style: TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 14),
                    ),
                  ),
                  _chip(link.hasLink ? "الرابط قائم" : "لا يوجد رابط", color),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metric("السرعة", link.rateLabel, color),
                  _metric("duplex", link.duplexLabel, _navy),
                  _metric(
                    "التفاوض التلقائي",
                    link.autoNegotiation == null ? "غير معروف" : (link.autoNegotiation! ? "مفعّل" : "معطّل"),
                    _navy,
                  ),
                ],
              ),
              if (degraded) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "سرعة مخفّضة: الراوتر يهبط إلى 100Mbps عندما لا تعمل الأزواج الأربعة كاملة. "
                    "راجع النتيجة أعلاه أو أعد ضغط أطراف الكيبل.",
                    style: TextStyle(color: _amber, fontSize: 11.5, height: 1.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: _slate, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // ===================== التشخيص والتوصيات =====================

  Widget _diagnosisSection() {
    return Obx(() {
      final diagnosis = controller.diagnosis.value;
      if (diagnosis == null) return const SizedBox.shrink();

      final color = _severityColor(diagnosis.severity);

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_navy, _blue],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_severityIcon(diagnosis.severity), color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "التشخيص",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      diagnosis.severity.severityLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                diagnosis.headline,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.6),
              ),
              if (diagnosis.details.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  diagnosis.details,
                  style: const TextStyle(color: const Color(0xB3E8EEF9), fontSize: 12, height: 1.7),
                ),
              ],
              if (diagnosis.recommendations.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  "التوصيات:",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                ...diagnosis.recommendations.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 5, color: const Color(0xB3E8EEF9)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: const Color(0xB3E8EEF9), fontSize: 11.5, height: 1.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // ===================== مساعدات =====================

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF243352)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
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

  Widget _rawLine(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2740),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: _slate, fontSize: 10.5, height: 1.5),
      ),
    );
  }

  Color _severityColor(CableSeverity severity) {
    switch (severity) {
      case CableSeverity.ok:
        return _green;
      case CableSeverity.warning:
        return _amber;
      case CableSeverity.fault:
        return _red;
      case CableSeverity.unknown:
        return _slate;
    }
  }

  IconData _severityIcon(CableSeverity severity) {
    switch (severity) {
      case CableSeverity.ok:
        return Icons.verified_rounded;
      case CableSeverity.warning:
        return Icons.warning_amber_rounded;
      case CableSeverity.fault:
        return Icons.dangerous_rounded;
      case CableSeverity.unknown:
        return Icons.help_outline_rounded;
    }
  }

  Color _pairColor(CablePairStatus status) {
    switch (status) {
      case CablePairStatus.ok:
        return _green;
      case CablePairStatus.open:
        return _red;
      case CablePairStatus.short:
        return const Color(0xFFEA580C);
      case CablePairStatus.cross:
        return _amber;
      case CablePairStatus.unknown:
        return _slate;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/ai_diagnosis_prompt.dart';

void main() {
  test('AI diagnosis prompt preserves measurements and safety constraints', () {
    final prompt = AIDiagnosisPrompt.build(
      gatewayIp: '192.168.88.1',
      tests: const [
        AIDiagnosticTestResult(
          id: 'gateway',
          title: 'اتصال الراوتر',
          status: 'success',
          message: 'تم الوصول إلى البوابة 192.168.88.1',
        ),
        AIDiagnosticTestResult(
          id: 'internet',
          title: 'اتصال الإنترنت الخارجي',
          status: 'error',
          message: 'تعذر الاتصال الخارجي',
        ),
        AIDiagnosticTestResult(
          id: 'latency',
          title: 'زمن الاستجابة',
          status: 'warning',
          message: 'المتوسط: 220 مللي ثانية',
          latencyMs: 220,
        ),
        AIDiagnosticTestResult(
          id: 'speed_test',
          title: 'اختبار سرعة الإنترنت',
          status: 'warning',
          message: 'التحميل: 0.80 Mbps',
          downloadSpeedMbps: 0.8,
          uploadSpeedMbps: 0.3,
        ),
      ],
    );

    expect(prompt, contains('192.168.88.1'));
    expect(prompt, contains('"latency_ms": 220.0'));
    expect(prompt, contains('"download_mbps": 0.8'));
    expect(prompt, contains('نجاح الإنترنت مع فشل DNS'));
    expect(prompt, contains('لا تطلب أو تعرض كلمات مرور أو مفاتيح API'));
    expect(prompt, contains('## خطة العمل الآمنة'));
    expect(prompt, contains('## بيانات مطلوبة لاستكمال التشخيص'));
  });

  test('AI diagnosis prompt omits absent gateway and optional measurements',
      () {
    final prompt = AIDiagnosisPrompt.build(
      gatewayIp: null,
      tests: const [
        AIDiagnosticTestResult(
          id: 'dns',
          title: 'فحص DNS',
          status: 'pending',
          message: 'لم يتم الفحص بعد',
        ),
      ],
    );

    expect(prompt, contains('"gateway_ip": null'));
    expect(prompt, isNot(contains('"latency_ms"')));
    expect(prompt, isNot(contains('"download_mbps"')));
  });
}

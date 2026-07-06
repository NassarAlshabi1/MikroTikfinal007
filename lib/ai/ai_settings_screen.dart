// ============================================================
//  AI Settings Screen — إعدادات مزود الـ AI ومفتاح API
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'diagnostics_models.dart';
import 'diagnostics_provider.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  late TextEditingController _apiKeyController;
  bool _obscureApiKey = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(aiSettingsNotifierProvider).valueOrNull ??
        AiSettings.default_;
    _apiKeyController = TextEditingController(text: settings.apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(aiSettingsNotifierProvider.notifier);
      await notifier.setApiKey(_apiKeyController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(aiSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الذكاء الاصطناعي'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== بطاقة معلومات =====
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb,
                            color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'كيف يعمل التشخيص؟',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. يجمع التطبيق بيانات من MikroTik (interfaces, routes, firewall, logs)\n'
                      '2. يرسلها مع سؤالك إلى الـ AI\n'
                      '3. يحلل الـ AI المشكلة ويقترح أوامر إصلاح\n'
                      '4. تنسخ الأوامر وتنفذها يدوياً',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== اختيار المزود =====
            const Text(
              'مزود الذكاء الاصطناعي',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AiProvider>(
              value: settings.provider,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: AiProvider.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName),
                      ))
                  .toList(),
              onChanged: (provider) {
                if (provider != null) {
                  ref
                      .read(aiSettingsNotifierProvider.notifier)
                      .setProvider(provider);
                }
              },
            ),
            const SizedBox(height: 16),

            // ===== اختيار الموديل =====
            const Text(
              'الموديل',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: settings.model,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: settings.provider.availableModels
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      ))
                  .toList(),
              onChanged: (model) {
                if (model != null) {
                  ref
                      .read(aiSettingsNotifierProvider.notifier)
                      .setModel(model);
                }
              },
            ),
            const SizedBox(height: 16),

            // ===== مفتاح API =====
            const Text(
              'مفتاح API',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: settings.provider == AiProvider.openAI
                    ? 'sk-...'
                    : 'AIza...',
                suffixIcon: IconButton(
                  icon: Icon(_obscureApiKey
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 8),

            // رابط الحصول على المفتاح
            InkWell(
              onTap: () async {
                // فتح رابط الحصول على مفتاح API
                // يُترك للمستخدم (url_launcher)
              },
              child: Text(
                settings.provider == AiProvider.openAI
                    ? 'احصل على مفتاح OpenAI من: platform.openai.com/api-keys'
                    : 'احصل على مفتاح Gemini من: aistudio.google.com/app/apikey',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ===== طريقة الاتصال بـ MikroTik =====
            const Text(
              'طريقة الاتصال بـ MikroTik',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MikrotikConnectionMethod>(
              value: settings.connectionMethod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: MikrotikConnectionMethod.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.displayName),
                      ))
                  .toList(),
              onChanged: (method) {
                if (method != null) {
                  ref
                      .read(aiSettingsNotifierProvider.notifier)
                      .setConnectionMethod(method);
                }
              },
            ),
            const SizedBox(height: 8),
            if (settings.connectionMethod == MikrotikConnectionMethod.ssh)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يتطلب SSH تفعيل خدمة SSH على MikroTik (منفذ 22). '
                        'استخدم نفس بيانات الدخول الحالية.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // ===== زر الحفظ =====
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات'),
            ),

            const SizedBox(height: 16),
            // ===== تحذير أمني =====
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'تنبيه أمني',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• مفتاح الـ API يُخزّن مشفّراً في الجهاز (flutter_secure_storage)\n'
                    '• لا يتم إرساله لأي طرف ثالث\n'
                    '• كل استدعاء للـ AI يكلّفك مالاً حسب سعر المزود\n'
                    '• اقتصر الـ logs على آخر 30 سطر لتوفير tokens',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

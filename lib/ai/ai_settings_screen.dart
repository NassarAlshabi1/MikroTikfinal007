// ============================================================
//  AI Settings Screen — إعدادات مزود الـ AI ومفتاح API
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'diagnostics_models.dart';
import 'diagnostics_provider.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  bool _obscureApiKey = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(aiSettingsNotifierProvider).valueOrNull ??
        AiSettings.default_;
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _baseUrlController = TextEditingController(text: settings.baseUrl ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(aiSettingsNotifierProvider.notifier);
      await notifier.setApiKey(_apiKeyController.text.trim());
      await notifier.setBaseUrl(_baseUrlController.text.trim());
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            // للمزود المخصص: حقل نص لإدخال اسم النموذج يدوياً
            // للآخرين: قائمة منسدلة
            if (settings.provider == AiProvider.custom) ...[
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'مثال: gpt-4o-mini أو llama-3.1-70b',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.white38),
                  prefixIcon: Icon(Icons.model_training, size: 18, color: Colors.white54),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                onChanged: (value) {
                  ref.read(aiSettingsNotifierProvider.notifier).setModel(value.trim());
                },
              ),
            ] else ...[
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
            ],
            const SizedBox(height: 16),

            // ===== حد خطوات الاستقصاء (التشخيص الوكيل) =====
            Row(
              children: [
                const Icon(Icons.psychology,
                    size: 18, color: Colors.deepPurpleAccent),
                const SizedBox(width: 6),
                const Text(
                  'حد خطوات الاستقصاء (التشخيص الوكيل)',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  '${settings.agenticMaxSteps}',
                  style: const TextStyle(
                      fontSize: 15,
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: settings.agenticMaxSteps.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '${settings.agenticMaxSteps}',
              activeColor: Colors.deepPurpleAccent,
              onChanged: (v) {
                ref
                    .read(aiSettingsNotifierProvider.notifier)
                    .setAgenticMaxSteps(v.round());
              },
            ),
            const Text(
              'كلما زاد العدد، استقصى الـ AI أعمق (أوامر قراءة تلقائية أكثر) '
              'مقابل استهلاك أكبر للـ tokens. الافتراضي 6.',
              style: TextStyle(fontSize: 11, color: Colors.white38),
            ),
            const SizedBox(height: 16),

            // ===== Custom Base URL =====
            Text(
              settings.provider == AiProvider.custom
                  ? 'API Endpoint (إلزامي للمزود المخصص)'
                  : 'API Endpoint مخصص (اختياري)',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: settings.provider == AiProvider.custom
                    ? 'https://api.xxx.com/v1 (إلزامي)'
                    : 'https://api.openai.com/v1 (اتركه فارغاً للافتراضي)',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                prefixIcon: const Icon(Icons.link, size: 18, color: Colors.white54),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              settings.provider == AiProvider.custom
                  ? 'أدخل عنوان API الكامل للمزود المتوافق مع OpenAI:\n'
                    '• OpenRouter: https://openrouter.ai/api/v1\n'
                    '• Ollama (محلي): http://localhost:11434/v1\n'
                    '• Together AI: https://api.together.xyz/v1\n'
                    '• Groq: https://api.groq.com/openai/v1\n'
                    '• أي مزود آخر متوافق مع OpenAI API'
                  : 'استخدم هذا للمزودين المتوافقين مع OpenAI API:\n'
                    '• OpenRouter: https://openrouter.ai/api/v1\n'
                    '• Azure OpenAI: https://{resource}.openai.azure.com/openai/deployments/{deployment}\n'
                    '• Ollama (محلي): http://localhost:11434/v1\n'
                    '• LocalAI: http://localhost:8080/v1\n'
                    '• Together AI: https://api.together.xyz/v1',
              style: TextStyle(fontSize: 11, color: Colors.white38),
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
                final url = settings.provider == AiProvider.openAI
                    ? 'https://platform.openai.com/api-keys'
                    : 'https://aistudio.google.com/app/apikey';
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تعذّر فتح الرابط: $url')),
                  );
                }
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
            // التشخيص والتنفيذ يتمّان عبر RouterOS API حصراً (منفذ 8728/8729)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الاتصال والتنفيذ يتمّان عبر RouterOS API (منفذ 8728/8729) '
                      'باستخدام بيانات الدخول الحالية.',
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
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'تنبيه أمني',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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

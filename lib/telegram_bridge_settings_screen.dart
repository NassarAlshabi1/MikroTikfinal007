import 'package:flutter/material.dart';

import 'services/secure_credentials_storage.dart';
import 'snackbar_helpers.dart';

/// Manages the Telegram bot credential used by the optional bridge service.
///
/// The token is deliberately stored through [SecureCredentialsStorage] and is
/// never logged or persisted in SharedPreferences by this screen.
class TelegramBridgeSettingsScreen extends StatefulWidget {
  const TelegramBridgeSettingsScreen({super.key});

  @override
  State<TelegramBridgeSettingsScreen> createState() =>
      _TelegramBridgeSettingsScreenState();
}

class _TelegramBridgeSettingsScreenState
    extends State<TelegramBridgeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    try {
      final token = await SecureCredentialsStorageContainer.instance
          .getTelegramBotToken();
      if (!mounted) return;
      _tokenController.text = token ?? '';
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(context, 'تعذر قراءة إعدادات Telegram الآمنة.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await SecureCredentialsStorageContainer.instance
          .setTelegramBotToken(_tokenController.text.trim());
      if (mounted) {
        showSuccessSnackBar(context, 'تم حفظ رمز Telegram بشكل آمن.');
      }
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(context, 'تعذر حفظ إعدادات Telegram.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    try {
      await SecureCredentialsStorageContainer.instance
          .setTelegramBotToken(null);
      _tokenController.clear();
      if (mounted) showSuccessSnackBar(context, 'تم حذف الرمز المحفوظ.');
    } catch (_) {
      if (mounted) showErrorSnackBar(context, 'تعذر حذف الرمز.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعداد جسر Telegram')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'يُحفظ رمز البوت في مخزن النظام المشفّر. شغّل خدمة '
                        'الجسر الخارجية واضبط قائمة المحادثات المسموح بها '
                        'على الخادم قبل الاستخدام.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _tokenController,
                      obscureText: _obscureToken,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'رمز Telegram Bot',
                        hintText: '123456:ABC…',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscureToken ? 'إظهار الرمز' : 'إخفاء الرمز',
                          onPressed: () => setState(
                            () => _obscureToken = !_obscureToken,
                          ),
                          icon: Icon(
                            _obscureToken
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final token = value?.trim() ?? '';
                        if (token.isEmpty) return 'أدخل رمز البوت.';
                        if (!RegExp(r'^\d+:[A-Za-z0-9_-]+$')
                            .hasMatch(token)) {
                          return 'صيغة الرمز غير صحيحة.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_outline),
                    label: const Text('حفظ آمن'),
                  ),
                  TextButton.icon(
                    onPressed: _saving || _tokenController.text.isEmpty
                        ? null
                        : _clear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('حذف الرمز'),
                  ),
                ],
              ),
            ),
    );
  }
}

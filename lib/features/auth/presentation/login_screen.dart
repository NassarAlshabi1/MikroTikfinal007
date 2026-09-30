import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/core/navigation/custom_page_route.dart';
import 'package:mikrotik_manager/features/dashboard/presentation/home_screen.dart';
import 'package:mikrotik_manager/mikrotik_connector.dart';
import 'package:mikrotik_manager/providers/app_theme_provider.dart';
import 'package:mikrotik_manager/services/secure_credentials_storage.dart';
import 'package:mikrotik_manager/snackbar_helpers.dart';
import 'package:mikrotik_manager/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _ipController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController(text: '8728');
  final _remoteServerController = TextEditingController();
  final _remotePortController = TextEditingController(text: '8728');
  final _remoteUserController = TextEditingController();
  final _remotePasswordController = TextEditingController();
  // L2TP VPN controllers
  final _l2tpServerController = TextEditingController();
  final _l2tpUserController = TextEditingController();
  final _l2tpPasswordController = TextEditingController();
  final _l2tpPortController = TextEditingController(text: '8728');
  String _l2tpDetectedRouterIp = '';

  bool _isLoading = false;
  String _errorMessage = '';
  bool _rememberMe = true;
  bool _rememberMeRemote = false;
  bool _isPasswordObscured = true;
  bool _isRemotePasswordObscured = true;
  bool _isScanning = false;
  bool _useSslRemote = true;
  bool _isVpnConnecting = false;
  bool _isVpnConnected = false;
  static const _vpnChannel = MethodChannel('com.mikrotik.manager/vpn');

  // إعدادات Telegram تُدار من شاشة "إعداد Telegram Bot"، ولا تُحفظ
  // داخل شاشة الدخول أو كثوابت في التطبيق.

  Future<void> _launchPrivacyPolicy() async {
    // تم تعطيل رابط سياسة الخصوصية
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _init();
  }

  Future<void> _init() async {
    try {
      await _loadSavedCredentials();
      await _discoverGateway();
    } catch (e, s) {
      debugPrint('Error in initState: $e\n$s');
    }
  }

  Future<void> _discoverGateway() async {
    if (_ipController.text.isNotEmpty) {
      return;
    }
    await _forceDiscoverGateway();
  }

  Future<void> _forceDiscoverGateway() async {
    setState(() {
      _isScanning = true;
      _errorMessage = 'جاري البحث عن بوابة الشبكة...';
    });
    try {
      final gatewayIp = await NetworkInfo().getWifiGatewayIP();
      if (gatewayIp != null && gatewayIp.isNotEmpty) {
        if (mounted) {
          setState(() {
            _ipController.text = gatewayIp;
            _errorMessage = 'تم العثور على بوابة الشبكة!';
          });
        }
      } else {
        if (mounted) {
          setState(() => _errorMessage =
              'لم يتم العثور على بوابة. تأكد من اتصالك بشبكة Wi-Fi.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'حدث خطأ أثناء محاولة اكتشاف الشبكة.');
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember_me') ?? false) {
      // 🔒 قراءة كلمة المرور من flutter_secure_storage
      final password = await SecureCredentialsStorageContainer.instance
              .getMikrotikPassword() ??
          '';
      setState(() {
        _ipController.text = prefs.getString('ip') ?? '';
        _userController.text = prefs.getString('user') ?? '';
        _passwordController.text = password;
        _portController.text = prefs.getString('port') ?? '8728';
        _rememberMe = true;
      });
    }
    if (prefs.getBool('remember_me_remote') ?? false) {
      // 🔒 قراءة كلمة المرور البعيدة من flutter_secure_storage
      final remotePass = await SecureCredentialsStorageContainer.instance
              .getRemotePassword() ??
          '';
      setState(() {
        _remoteServerController.text = prefs.getString('remote_server') ?? '';
        _remotePortController.text = prefs.getString('remote_port') ?? '8729';
        _remoteUserController.text = prefs.getString('remote_user') ?? '';
        _remotePasswordController.text = remotePass;
        _useSslRemote = prefs.getString('use_ssl') != 'false';
        _rememberMeRemote = true;
      });
    }
    // تحميل إعدادات L2TP VPN
    if (prefs.getBool('remember_l2tp') ?? false) {
      setState(() {
        _l2tpServerController.text = prefs.getString('l2tp_server') ?? '';
        _l2tpUserController.text = prefs.getString('l2tp_user') ?? '';
        _l2tpPortController.text = prefs.getString('l2tp_port') ?? '8728';
      });
    }
  }

  Future<void> _handleCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    // 🔧 إصلاح حرج: نحفظ بيانات الاتصال دائماً (مؤقتاً) لكي يستطيع
    // MikrotikConnector.connect() قراءتها. خيار "تذكرني" يتحكم فقط
    // في إعادة التعبئة التلقائية عند بدء التطبيق لاحقاً.
    // 🔒 الأمان: كلمة المرور تُحفظ في flutter_secure_storage (مشفّرة AES-256-GCM)
    // بدل SharedPreferences (plaintext).
    await prefs.setString('ip', _ipController.text);
    await prefs.setString('user', _userController.text);
    await SecureCredentialsStorageContainer.instance
        .setMikrotikPassword(_passwordController.text);
    await prefs.setString('port', _portController.text);
    // إن لم يفعّل "تذكرني"، نمسح بيانات الدخول عند تسجيل الخروج
    // (وليس قبل الاتصال — هذا ما كان يسبب الفشل!)
    if (!_rememberMe) {
      // نضع علامة لمسح البيانات بعد الخروج
      await prefs.setBool('clear_on_logout', true);
    } else {
      await prefs.setBool('clear_on_logout', false);
    }
  }

  Future<void> _handleRemoteCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me_remote', _rememberMeRemote);
    // 🔧 إصلاح حرج: نحفظ بيانات الاتصال البعيد دائماً
    // لكي يستطيع MikrotikConnector.connect() قراءتها
    await prefs.setString('remote_server', _remoteServerController.text);
    await prefs.setString('remote_port', _remotePortController.text);
    await prefs.setString('remote_user', _remoteUserController.text);
    // 🔒 كلمة المرور البعيدة في flutter_secure_storage
    await SecureCredentialsStorageContainer.instance
        .setRemotePassword(_remotePasswordController.text);
  }

  Future<void> _login() async {
    if (_ipController.text.isEmpty || _userController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال IP واسم المستخدم');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await _handleCredentials();
      await MikrotikConnector.connect();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            builder: (context) => HomeScreen(
                isVersion7OrNewer: false, username: _userController.text),
          ),
        );
      }
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'خطأ في بيانات الدخول: ${e.message}');
        showErrorSnackBar(context, 'خطأ في بيانات الدخول: ${e.message}');
      }
    } on MikrotikConnectionException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'خطأ في الاتصال: ${e.message}');
        showErrorSnackBar(context, 'خطأ في الاتصال: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            'فشل الاتصال. تحقق من البيانات أو الشبكة.\n(الخطأ: ${e.toString()})');
        showErrorSnackBar(context, 'فشل الاتصال. تحقق من البيانات أو الشبكة.');
      }
    } finally {
      // 🔧 إصلاح حرج: لا نغلق الاتصال هنا!
      // الاتصال مُخزّن في MikrotikConnector._cachedClient لإعادة استخدامه
      // في كل الشاشات اللاحقة (Hotspot, Cards, Stats, AI, ...)
      // إغلاقه هنا كان يسبب فشل كل العمليات بعد الـ login
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _remoteServerController.dispose();
    _remotePortController.dispose();
    _remoteUserController.dispose();
    _remotePasswordController.dispose();
    _l2tpServerController.dispose();
    _l2tpUserController.dispose();
    _l2tpPasswordController.dispose();
    _l2tpPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.theme.appColors.background,
            context.theme.appColors.surface,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // المحتوى الرئيسي
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Image.asset('assets/images/wifi_logo.png',
                        width: 48, height: 48),
                    const SizedBox(height: 24),
                    Text(
                      'إدارة شبكتك بسهولة وأمان',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: context.theme.appColors.primary,
                        labelColor: context.theme.appColors.onSurface,
                        unselectedLabelColor: context.theme.appColors.muted,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.lan),
                            text: 'اتصال محلي',
                          ),
                          Tab(
                            icon: Icon(Icons.cloud),
                            text: 'اتصال عن بعد',
                          ),
                          Tab(
                            icon: Icon(Icons.vpn_lock),
                            text: 'L2TP VPN',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.theme.appColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 550,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildLocalLoginForm(),
                          _buildRemoteLoginForm(),
                          _buildL2TPForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // مفتاح تبديل الثيم في الزاوية العلوية اليسرى
            Positioned(
              top: 50,
              left: 20,
              child: Consumer(
                builder: (context, ref, _) {
                  final themeProvider = ref.watch(appThemeProvider);
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          key: ValueKey(themeProvider.isDarkMode),
                          color: themeProvider.isDarkMode
                              ? Theme.of(context).appColors.warning
                              : Theme.of(context).appColors.primary,
                          size: 26,
                        ),
                      ),
                      tooltip: themeProvider.isDarkMode
                          ? 'التبديل للثيم الفاتح'
                          : 'التبديل للثيم الغامق',
                      onPressed: () async {
                        await themeProvider.toggleTheme();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    themeProvider.isDarkMode
                                        ? 'تم التبديل للثيم الغامق'
                                        : 'تم التبديل للثيم الفاتح',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remoteConnect() async {
    if (_remoteServerController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال عنوان الخادم البعيد');
      return;
    }

    if (_remoteUserController.text.isEmpty ||
        _remotePasswordController.text.isEmpty) {
      setState(() => _errorMessage =
          'الرجاء إدخال اسم المستخدم وكلمة المرور للاتصال البعيد');
      return;
    }

    final input = _remoteServerController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال عنوان الخادم');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _handleRemoteCredentials();

      // حفظ إعدادات الاتصال البعيد في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ip', _remoteServerController.text.trim());
      final remotePort = _remotePortController.text.trim().isEmpty
          ? (_useSslRemote ? '8729' : '8728')
          : _remotePortController.text.trim();
      await prefs.setString('port', remotePort);
      await prefs.setString('user', _remoteUserController.text.trim());
      await prefs.setString('use_ssl', _useSslRemote.toString());
      // 🔒 كلمة المرور في flutter_secure_storage (مشفّرة)
      await SecureCredentialsStorageContainer.instance
          .setMikrotikPassword(_remotePasswordController.text);

      // 🔧 اختبار الاتصال قبل الانتقال إلى الشاشة الرئيسية
      // (مطابق لسلوك الاتصال المحلي)
      await MikrotikConnector.connect();

      if (mounted) {
        showSuccessSnackBar(context, 'تم الاتصال بالراوتر بنجاح');
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            builder: (context) => HomeScreen(
              isVersion7OrNewer: false,
              username: _remoteUserController.text.trim(),
            ),
          ),
        );
      }
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'خطأ في بيانات الدخول: ${e.message}');
        showErrorSnackBar(context, 'خطأ في بيانات الدخول: ${e.message}');
      }
    } on MikrotikConnectionException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'خطأ في الاتصال: ${e.message}');
        showErrorSnackBar(context, 'خطأ في الاتصال: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            'فشل الاتصال. تحقق من العنوان أو المنفذ أو الشبكة.\n(الخطأ: ${e.toString()})');
        showErrorSnackBar(context, 'فشل الاتصال. تحقق من البيانات أو الشبكة.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLocalLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                    labelText: 'IP Address', prefixIcon: Icon(Icons.lan)),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: context.theme.appColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isScanning
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        color: context.theme.appColors.primary,
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.search,
                          color: context.theme.appColors.primary),
                      onPressed: _forceDiscoverGateway,
                      tooltip: 'بحث عن البوابة',
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _userController,
          decoration: const InputDecoration(
              labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _isPasswordObscured,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordObscured
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () =>
                  setState(() => _isPasswordObscured = !_isPasswordObscured),
            ),
          ),
        ),
        CheckboxListTile(
          title: const Text("تذكرني"),
          value: _rememberMe,
          onChanged: (newValue) =>
              setState(() => _rememberMe = newValue ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: context.theme.appColors.primary,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          child: _isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: context.theme.appColors.onPrimary))
              : const Text('اتصال', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _launchPrivacyPolicy,
          child: Text(
            'سياسة الخصوصية',
            style: TextStyle(
              color:
                  context.theme.appColors.onBackground.withValues(alpha: 0.7),
              decoration: TextDecoration.underline,
              decorationColor:
                  context.theme.appColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'جميع الحقوق محفوظة © م/نصار الشعبي',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.theme.appColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildL2TPForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // عنوان L2TP Server
        TextField(
          controller: _l2tpServerController,
          decoration: const InputDecoration(
            labelText: 'عنوان VPN (IP أو Domain)',
            hintText: 'vpn.example.com أو 1.2.3.4',
            prefixIcon: Icon(Icons.vpn_lock),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        // اسم المستخدم
        TextField(
          controller: _l2tpUserController,
          decoration: const InputDecoration(
            labelText: 'اسم المستخدم',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        // كلمة المرور
        TextField(
          controller: _l2tpPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'كلمة المرور',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 12),
        // منفذ الراوتر
        TextField(
          controller: _l2tpPortController,
          decoration: const InputDecoration(
            labelText: 'منفذ الراوتر',
            hintText: '8728',
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
        ),
        if (_l2tpDetectedRouterIp.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.theme.appColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    size: 16, color: context.theme.appColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'راوتر مكتشف: $_l2tpDetectedRouterIp',
                    style: TextStyle(
                        fontSize: 11, color: context.theme.appColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // زر الاتصال
        ElevatedButton.icon(
          onPressed: (_isLoading || _isVpnConnecting) ? null : _l2tpConnect,
          icon: (_isLoading || _isVpnConnecting)
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isVpnConnected ? Icons.check_circle : Icons.vpn_lock),
          label: Text(
            _isVpnConnecting
                ? 'جاري إنشاء اتصال VPN...'
                : _isVpnConnected
                    ? 'VPN متصل — اضغط للاتصال بالراوتر'
                    : 'إنشاء اتصال L2TP VPN',
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        if (_isVpnConnected)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _l2tpLoginToRouter,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(_isLoading ? 'جاري الاتصال...' : 'الدخول للراوتر'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: context.theme.appColors.success,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          _isVpnConnected
              ? '✅ اتصال VPN نشط — يمكنك الآن الاتصال بالراوتر'
              : 'أدخل عنوان VPN + اسم المستخدم + كلمة المرور',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.theme.appColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Text(
          'جميع الحقوق محفوظة © م/نصار الشعبي',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.theme.appColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  /// إنشاء اتصال L2TP VPN عبر Android VPN Service
  Future<void> _l2tpConnect() async {
    if (_l2tpServerController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال عنوان VPN');
      return;
    }
    if (_l2tpUserController.text.isEmpty ||
        _l2tpPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() {
      _isVpnConnecting = true;
      _errorMessage = '';
    });

    try {
      // حفظ إعدادات L2TP
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_l2tp', true);
      await prefs.setString('l2tp_server', _l2tpServerController.text.trim());
      await prefs.setString('l2tp_user', _l2tpUserController.text.trim());
      await prefs.setString('l2tp_port', _l2tpPortController.text.trim());

      // حفظ كلمة المرور في التخزين الآمن
      await SecureCredentialsStorageContainer.instance
          .setL2tpPassword(_l2tpPasswordController.text);

      // بدء VPN عبر MethodChannel (Android فقط)
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final result = await _vpnChannel.invokeMethod('startVpn', {
            'server': _l2tpServerController.text.trim(),
            'secret': '',
            'user': _l2tpUserController.text.trim(),
            'password': _l2tpPasswordController.text,
            'routerIp': '',
          });

          if (result is Map) {
            final status = result['status'] as String?;
            if (status == 'permission_needed') {
              setState(() => _isVpnConnecting = false);
              if (mounted) {
                showSuccessSnackBar(
                    context, 'يرجى منح صلاحية VPN في نافذة النظام');
              }
              return;
            }
          }

          // انتظار قليل ثم اكتشاف الراوتر تلقائياً
          await Future.delayed(const Duration(seconds: 3));
          final detectedIp = await _detectRouterIp();

          setState(() {
            _isVpnConnected = true;
            _isVpnConnecting = false;
            _l2tpDetectedRouterIp = detectedIp;
          });
          if (mounted) {
            final msg = detectedIp.isNotEmpty
                ? '✅ VPN متصل — راوتر مكتشف: $detectedIp'
                : 'تم إنشاء اتصال VPN — اضغط "الدخول للراوتر"';
            showSuccessSnackBar(context, msg);
          }
        } on PlatformException catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'خطأ في بدء VPN: ${e.message}';
              _isVpnConnecting = false;
            });
          }
        }
      } else {
        // غير Android - VPN غير مدعوم
        setState(() {
          _isVpnConnected = true;
          _isVpnConnecting = false;
        });
        if (mounted) {
          showSuccessSnackBar(context, 'تم إعداد VPN — اضغط "الدخول للراوتر"');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل إعداد VPN: ${e.toString()}';
          _isVpnConnecting = false;
        });
      }
    }
  }

  /// اكتشاف عنوان الراوتر داخل VPN تلقائياً
  Future<String> _detectRouterIp() async {
    try {
      final gatewayIp = await NetworkInfo().getWifiGatewayIP();
      if (gatewayIp != null && gatewayIp.isNotEmpty) {
        return gatewayIp;
      }
    } catch (_) {}
    // محاولة IPs شائعة للراوترات
    return '';
  }

  /// الاتصال بالراوتر عبر VPN
  Future<void> _l2tpLoginToRouter() async {
    if (_l2tpUserController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال اسم المستخدم');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // اكتشاف أو استخدام عنوان الراوتر
      String routerIp = _l2tpDetectedRouterIp;
      if (routerIp.isEmpty) {
        routerIp = await _detectRouterIp();
        if (routerIp.isEmpty) {
          setState(() {
            _errorMessage = 'لم يتم اكتشاف الراوتر. تأكد من اتصال VPN.';
            _isLoading = false;
          });
          return;
        }
        setState(() => _l2tpDetectedRouterIp = routerIp);
      }

      // حفظ إعدادات الراوتر في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ip', routerIp);
      final port = _l2tpPortController.text.trim().isEmpty
          ? '8728'
          : _l2tpPortController.text.trim();
      await prefs.setString('port', port);
      await prefs.setString('user', _l2tpUserController.text.trim());
      await prefs.setString('use_ssl', 'false');

      // كلمة المرور = كلمة مرور L2TP
      await SecureCredentialsStorageContainer.instance
          .setMikrotikPassword(_l2tpPasswordController.text);

      // اختبار الاتصال بالراوتر
      await MikrotikConnector.connect();

      if (mounted) {
        showSuccessSnackBar(context, 'تم الاتصال بالراوتر عبر VPN بنجاح');
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            builder: (context) => HomeScreen(
              isVersion7OrNewer: false,
              username: _l2tpUserController.text.trim(),
            ),
          ),
        );
      }
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'خطأ في بيانات الدخول: ${e.message}');
        showErrorSnackBar(context, 'خطأ في بيانات الدخول: ${e.message}');
      }
    } on MikrotikConnectionException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'خطأ في الاتصال: ${e.message}');
        showErrorSnackBar(context, 'خطأ في الاتصال: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            'فشل الاتصال بالراوتر. تأكد من أن VPN نشط والراوتر متاح.\n(الخطأ: ${e.toString()})');
        showErrorSnackBar(context, 'فشل الاتصال بالراوتر عبر VPN');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRemoteLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _remoteServerController,
          decoration: const InputDecoration(
            labelText: 'عنوان الخادم البعيد (Domain أو IP)',
            hintText: 'router.example.com أو 192.168.1.1',
            prefixIcon: Icon(Icons.cloud),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _remotePortController,
                decoration: InputDecoration(
                  labelText: 'Port',
                  hintText: _useSslRemote ? '8729 (SSL)' : '8728',
                  prefixIcon: const Icon(Icons.numbers),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SSL',
                    style: TextStyle(
                        fontSize: 12,
                        color: context.theme.appColors.onSurface)),
                Switch(
                  value: _useSslRemote,
                  onChanged: (value) => setState(() {
                    _useSslRemote = value;
                    if (_remotePortController.text == '8728' ||
                        _remotePortController.text == '8729') {
                      _remotePortController.text = value ? '8729' : '8728';
                    }
                  }),
                  activeThumbColor: context.theme.appColors.primary,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remoteUserController,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remotePasswordController,
          obscureText: _isRemotePasswordObscured,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isRemotePasswordObscured
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(
                  () => _isRemotePasswordObscured = !_isRemotePasswordObscured),
            ),
          ),
        ),
        CheckboxListTile(
          title: Text('تذكرني',
              style: TextStyle(color: context.theme.appColors.onSurface)),
          value: _rememberMeRemote,
          onChanged: (bool? value) {
            setState(() {
              _rememberMeRemote = value ?? false;
            });
          },
          activeColor: context.theme.appColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _remoteConnect,
          child: _isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                )
              : const Text('الدخول', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _launchPrivacyPolicy,
          child: Text(
            'سياسة الخصوصية',
            style: TextStyle(
              color:
                  context.theme.appColors.onBackground.withValues(alpha: 0.7),
              decoration: TextDecoration.underline,
              decorationColor:
                  context.theme.appColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _useSslRemote
              ? 'الاتصال الآمن عبر API-SSL (منفذ 8729)'
              : 'الاتصال عبر API غير المشفر (منفذ 8728) — يُنصح بالاستخدام الآمن',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.theme.appColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Text(
          'جميع الحقوق محفوظة © م/نصار الشعبي',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.theme.appColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

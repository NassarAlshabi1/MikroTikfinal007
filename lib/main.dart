// main.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

// Riverpod providers
import 'providers/app_theme_provider.dart';
import 'providers/mqtt_service_provider.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔒 Security services (من مهارة flutter-security)
import 'services/app_logger.dart';
import 'services/secure_credentials_storage.dart';
import 'services/mikrotik_service_mode.dart';
import 'services/user_manager_profile_parser.dart';

// --- افترض أن هذه الملفات موجودة في مشروعك ---
import 'add_user_screen.dart';
import 'bulk_add_screen.dart';
import 'saved_files_screen.dart';
import 'mqtt_service.dart';
import 'pdf_templates_screen.dart';
import 'network_doctor_screen.dart';
import 'extract_cards_screen.dart';
import 'cards_sync_screen.dart';
import 'stats_screen.dart';
import 'mikrotik_connector.dart';
import 'backup_system_screen.dart';
import 'active_users_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_gradients.dart';
import 'theme/professional_theme.dart';
// ===== Imports من capy/v2-riverpod (AI + terminal + perf + database) =====
import 'ai_diagnostics_screen.dart';
import 'terminal_screen.dart';
import 'ai/log_analysis_screen.dart';
import 'database/isar_provider.dart';
import 'database/migration_service.dart';
import 'monthly_report_screen.dart';
import 'card_search_screen.dart';
import 'telegram_bot_settings_screen.dart';
// -----------------------------------------

/// قاعدة البيانات العامة (Isar Singleton — تُستخدم عبر كل التطبيق)
late final IsarProvider appDatabaseProvider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  appDatabaseProvider = IsarProvider();
  try {
    await appDatabaseProvider.instance;
    AppLogger.info(
      'Isar database opened successfully',
      category: LogCategory.system,
    );

    // 🔒 انقل الأسرار أولًا، ثم البيانات القديمة إلى Isar.
    await SecureCredentialsStorageContainer.instance
        .migrateFromSharedPreferences();
    await MigrationService.instance.migrateLegacyDataIfNeeded();
  } catch (error, stackTrace) {
    // لا نكسر شاشة الدخول عند فشل ترحيل قديم، لكن نسجل الفشل كي يظهر
    // في تقارير التشخيص وتُعاد المحاولة في التشغيل التالي.
    AppLogger.error(
      'Application bootstrap migration failed',
      error: error,
      stackTrace: stackTrace,
      category: LogCategory.system,
    );
  }

  AppLogger.info('App starting', category: LogCategory.system);

  runApp(
    // 🔧 Riverpod ProviderScope — مطلوب لكل شاشات Riverpod
    // + Provider for MqttService و AppTheme (للتوافق مع الشاشات القديمة)
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => MqttService()),
          provider.ChangeNotifierProvider(
              create: (_) => AppTheme()..initialize()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

// A global key for the ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/* snackbar helpers moved to snackbar_helpers.dart */
void showErrorSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.onSurface, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).appColors.error,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'إغلاق',
        textColor: Theme.of(context).colorScheme.onSurface,
        onPressed: () {},
      ),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.onSurface, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).appColors.success,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeProvider).themeMode;
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'MikroTik Manager',
      theme: ProfessionalTheme.light,
      darkTheme: ProfessionalTheme.dark,
      themeMode: themeMode,
      home: const LoginScreen(),
    );
  }
}

// صفحة انتقال مخصصة مع animation
class CustomPageRoute<T> extends MaterialPageRoute<T> {
  CustomPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

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
                ),
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
                Icon(Icons.check_circle, size: 16, color: context.theme.appColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'راوتر مكتشف: $_l2tpDetectedRouterIp',
                    style: TextStyle(fontSize: 11, color: context.theme.appColors.success),
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
    if (_l2tpUserController.text.isEmpty || _l2tpPasswordController.text.isEmpty) {
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
              if (mounted) showSuccessSnackBar(context, 'يرجى منح صلاحية VPN في نافذة النظام');
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

class CustomLoadingIndicator extends StatelessWidget {
  final String? message;
  const CustomLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor:
                AlwaysStoppedAnimation<Color>(context.theme.appColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color:
                    context.theme.appColors.onBackground.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// --- HomeScreen with new UI ---
enum MikrotikMode { userManager, hotspot }

class HomeScreen extends ConsumerStatefulWidget {
  final bool isVersion7OrNewer;
  final String username;

  const HomeScreen({
    super.key,
    required this.isVersion7OrNewer,
    required this.username,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// --- Data class for Service items ---
class ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoadingProfiles = true;
  // فئات الكروت في شاشة الإدارة مصدرها User Manager فقط.
  bool _isNetworkLinked = false;
  String _clientName = '';

  Map<String, dynamic>? _dashboardStatus;
  bool _isLoadingStatus = true;
  bool _isRefreshingStatus = false;
  String _statusError = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchProfiles();
    _loadLinkStatus();
    _loadCachedDashboardStatus();
    _refreshDashboardStatus();
  }

  Future<void> _loadLinkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final isLinked = prefs.getBool('is_network_linked') ?? false;
      String clientName = '';
      if (isLinked) {
        final dataString = prefs.getString('qahtani_linked_data');
        if (dataString != null) {
          try {
            final data = jsonDecode(dataString);
            clientName = data['client_info']?['name'] ?? '';
          } catch (e) {
            debugPrint('Error decoding qahtani_linked_data: $e');
          }
        }
      }
      setState(() {
        _isNetworkLinked = isLinked;
        _clientName = clientName;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      _loadLinkStatus(); // Reload status on resume              ref.read(mqttServiceProvider).checkAndReconnect();
      final isLinked = _isNetworkLinked; // Use the state variable
      if (isLinked) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          ref
              .read(mqttServiceProvider)
              .publish({'command': 'get_latest_network_details'});
        });
      }
    }
  }

  Future<void> _loadCachedDashboardStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_dashboard_status') ??
        prefs.getString('cached_stats');
    if (cached == null) return;
    try {
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) return;
      if (!mounted) return;
      setState(() {
        _dashboardStatus = {
          'cpuUsage': (decoded['cpuUsage'] as num?)?.toDouble() ?? 0.0,
          'memoryUsage': (decoded['memoryUsage'] as num?)?.toDouble() ?? 0.0,
          'uptime': decoded['uptime']?.toString() ?? 'غير متوفر',
          'dataDownloaded':
              (decoded['dataDownloaded'] as num?)?.toDouble() ?? 0.0,
          'dataUploaded': (decoded['dataUploaded'] as num?)?.toDouble() ?? 0.0,
          'activeUsers': (decoded['activeUsers'] as num?)?.toInt() ?? 0,
          'version': decoded['version']?.toString() ?? 'غير معروف',
        };
        _isLoadingStatus = false;
        _statusError = '';
      });
    } catch (_) {
      // ignore cache parse errors
    }
  }

  Future<void> _refreshDashboardStatus({bool silent = true}) async {
    if (!mounted) return;
    setState(() {
      _statusError = '';
      if (silent && _dashboardStatus != null) {
        _isRefreshingStatus = true;
      } else {
        _isLoadingStatus = true;
      }
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final resourceResponse = await client.talk(['/system/resource/print']);
      Map<String, dynamic> resourceData = {};
      if (resourceResponse.isNotEmpty) {
        resourceData = Map<String, dynamic>.from(resourceResponse[0]);
      }

      final interfaceResponse = await client.talk([
        '/interface/print',
        '=.proplist=name,rx-byte,tx-byte',
        'stats',
      ]);
      double totalDownload = 0.0;
      double totalUpload = 0.0;
      for (var iface in interfaceResponse) {
        final rxBytes =
            double.tryParse(iface['rx-byte']?.toString() ?? '0') ?? 0.0;
        final txBytes =
            double.tryParse(iface['tx-byte']?.toString() ?? '0') ?? 0.0;
        totalDownload += rxBytes;
        totalUpload += txBytes;
      }

      List<Map<String, dynamic>> activeUsers = [];
      try {
        final activeResponse = await client.talk(['/ip/hotspot/active/print']);
        activeUsers =
            activeResponse.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        activeUsers = [];
      }

      final cpuLoad =
          double.tryParse(resourceData['cpu-load']?.toString() ?? '0') ?? 0.0;
      final totalMemory =
          double.tryParse(resourceData['total-memory']?.toString() ?? '0') ??
              0.0;
      final freeMemory =
          double.tryParse(resourceData['free-memory']?.toString() ?? '0') ??
              0.0;
      final memoryUsagePercent = totalMemory <= 0
          ? 0.0
          : ((totalMemory - freeMemory) / totalMemory * 100);

      final updatedStatus = {
        'cpuUsage': cpuLoad,
        'memoryUsage': memoryUsagePercent,
        'uptime': resourceData['uptime']?.toString() ?? 'غير متوفر',
        'dataDownloaded': totalDownload / (1024 * 1024),
        'dataUploaded': totalUpload / (1024 * 1024),
        'activeUsers': activeUsers.length,
        'version': resourceData['version']?.toString() ?? 'غير معروف',
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'cached_dashboard_status', jsonEncode(updatedStatus));

      if (mounted) {
        setState(() {
          _dashboardStatus = updatedStatus;
          _isLoadingStatus = false;
          _isRefreshingStatus = false;
          _statusError = '';
        });
      }
    } on MikrotikCredentialsMissingException catch (e) {
      _handleStatusError('بيانات الدخول غير متوفرة: ${e.message}');
    } on MikrotikConnectionException catch (e) {
      _handleStatusError('تعذر الاتصال بالجهاز: ${e.message}');
    } catch (e) {
      _handleStatusError('فشل تحديث حالة MikroTik: ${e.toString()}');
    } finally {
      MikrotikConnector.release(client);
    }
  }

  void _handleStatusError(String message) {
    if (!mounted) return;
    setState(() {
      _statusError = message;
      _isLoadingStatus = false;
      _isRefreshingStatus = false;
    });
    showErrorSnackBar(context, message);
  }

  static const _userManagerProfilesCommand = '/tool/user-manager/profile/print';

  MikrotikServiceMode get _serviceMode => MikrotikServiceMode.userManager;

  Future<void> _fetchProfiles() async {
    if (mounted) setState(() => _isLoadingProfiles = true);
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      var response = await client.talk([
        _userManagerProfilesCommand,
        '=.proplist=.id,name,rate-limit,shared-users,session-timeout',
      ]);
      var profiles = UserManagerProfileParser.parse(
        response
            .whereType<Map>()
            .map((profile) => Map<String, dynamic>.from(profile)),
      );

      // بعض إصدارات User Manager v6 أو wrappers القديمة لا تعيد الحقول
      // عند استخدام proplist؛ أعد القراءة بدون proplist قبل اعتبار النتيجة
      // فارغة، مع إبقاء المسار User Manager فقط.
      if (profiles.isEmpty) {
        response = await client.talk([_userManagerProfilesCommand]);
        profiles = UserManagerProfileParser.parse(
          response
              .whereType<Map>()
              .map((profile) => Map<String, dynamic>.from(profile)),
        );
      }

      if (mounted) {
        setState(() {
          _profiles = profiles;
        });
        if (profiles.isEmpty) {
          showSuccessSnackBar(
            context,
            'تم الاتصال بـ User Manager، لكن لا توجد فئات بروفايل بعد. '
            'أنشئ فئة من User Manager ثم اضغط تحديث.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'تعذر جلب فئات User Manager من MikroTik: $e',
        );
      }
    } finally {
      MikrotikConnector.release(client);
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- قائمة الخدمات لتسهيل إدارتها ---
    final List<ServiceItem> services = [
      ServiceItem(
        title: 'إضافة كرت فردي',
        icon: Icons.person_add_alt_1,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
            builder: (context) => AddUserScreen(
                profiles: _profiles,
                isVersion7OrNewer: false,
                customer: widget.username,
                serviceMode: _serviceMode),
          ));
        },
      ),
      ServiceItem(
        title: 'إضافة كروت جماعية',
        icon: Icons.groups,
        color: context.theme.appColors.success,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
            builder: (context) => BulkAddScreen(
                profiles: _profiles,
                isVersion7OrNewer: false,
                username: widget.username,
                serviceMode: _serviceMode),
          ));
        },
      ),
      ServiceItem(
        title: 'الإحصائيات',
        icon: Icons.bar_chart_rounded,
        color: context.theme.appColors.secondary,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const StatsScreen()));
        },
      ),
      ServiceItem(
        title: 'طبيب الشبكة',
        icon: Icons.local_hospital_outlined,
        color: context.theme.appColors.info,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const NetworkDoctorScreen()));
        },
      ),
      ServiceItem(
        title: 'الملفات المحفوظة',
        icon: Icons.folder_copy,
        color: context.theme.appColors.warning,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const SavedFilesScreen()));
        },
      ),
      ServiceItem(
        title: 'إدارة قوالب PDF',
        icon: Icons.picture_as_pdf,
        color: context.theme.appColors.muted,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => PdfTemplatesScreen(profiles: _profiles)));
        },
      ),
      ServiceItem(
        title: 'استخراج الكروت',
        icon: Icons.document_scanner_outlined,
        color: context.theme.appColors.error,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const ExtractCardsScreen()));
        },
      ),
      ServiceItem(
        title: 'مزامنة الكروت',
        icon: Icons.sync,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const CardsSyncScreen()));
        },
      ),
      ServiceItem(
        title: 'المستخدمين النشطين',
        icon: Icons.people_outline,
        color: context.theme.appColors.secondary,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const ActiveUsersScreen()));
        },
      ),
      ServiceItem(
        title: 'النسخ الاحتياطي',
        icon: Icons.backup,
        color: context.theme.appColors.info,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const BackupSystemScreen()));
        },
      ),
      // ===== شاشات AI + Terminal + إضافات capy/v2-riverpod =====
      ServiceItem(
        title: 'تشخيص بالذكاء الاصطناعي',
        icon: Icons.smart_toy,
        color: context.theme.appColors.secondary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const AiDiagnosticsScreen()));
        },
      ),
      ServiceItem(
        title: 'محطة RouterOS التفاعلية',
        icon: Icons.terminal,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const TerminalScreen()));
        },
      ),
      ServiceItem(
        title: 'تحليل Logs MikroTik',
        icon: Icons.analytics,
        color: context.theme.appColors.success,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const LogAnalysisScreen()));
        },
      ),
      ServiceItem(
        title: 'بحث الكروت',
        icon: Icons.search,
        color: context.theme.appColors.warning,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const CardSearchScreen()));
        },
      ),
      ServiceItem(
        title: 'التقرير الشهري',
        icon: Icons.calendar_month,
        color: context.theme.appColors.info,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const MonthlyReportScreen()));
        },
      ),
      ServiceItem(
        title: 'إعداد Telegram Bot',
        icon: Icons.telegram,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const TelegramBotSettingsScreen()));
        },
      ),
    ];

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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: null,
          centerTitle: false,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(Icons.person_outline,
                  color: context.theme.appColors.onSurface),
            ),
          ),
          actions: [
            // مفتاح تبديل الثيم الفاتح/الغامق
            Consumer(
              builder: (context, ref, child) {
                final themeProvider = ref.watch(appThemeProvider);
                return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    key: ValueKey(themeProvider.isDarkMode),
                    color: themeProvider.isDarkMode
                        ? Theme.of(context).appColors.warning
                        : Theme.of(context).appColors.primary,
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
                        content: Text(
                          themeProvider.isDarkMode
                              ? 'تم التبديل للثيم الغامق'
                              : 'تم التبديل للثيم الفاتح',
                          style: const TextStyle(fontSize: 14),
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
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث الحالة',
              onPressed: _isRefreshingStatus
                  ? null
                  : () => _refreshDashboardStatus(silent: false),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  CustomPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: _isLoadingProfiles
            ? const CustomLoadingIndicator(message: 'جاري التحميل...')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: _buildDashboardStatusCard(),
                    ),
                    if (_statusError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _statusError,
                          style: TextStyle(
                            color: context.theme.appColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: services.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return RepaintBoundary(
                          child: _buildServiceGridItem(
                            title: service.title,
                            icon: service.icon,
                            iconBgColor: service.color,
                            onTap: service.onTap,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDashboardStatusCard() {
    if (_isLoadingStatus && _dashboardStatus == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).textTheme.bodySmall!.color!,
              Theme.of(context).colorScheme.onSurface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 16),
            Text('جاري تحديث حالة MikroTik...'),
          ],
        ),
      );
    }

    final status = _dashboardStatus ??
        {
          'cpuUsage': 0.0,
          'memoryUsage': 0.0,
          'uptime': 'غير متوفر',
          'dataDownloaded': 0.0,
          'dataUploaded': 0.0,
          'activeUsers': 0,
          'version': 'غير معروف',
        };

    final cpuUsage = _asDouble(status['cpuUsage']);
    final memoryUsage = _asDouble(status['memoryUsage']);
    final downloadMb = _asDouble(status['dataDownloaded']);
    final uploadMb = _asDouble(status['dataUploaded']);
    final activeUsers = (status['activeUsers'] is num)
        ? (status['activeUsers'] as num).toInt()
        : int.tryParse(status['activeUsers']?.toString() ?? '') ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  context.theme.appColors.primary.withValues(alpha: 0.32),
                  context.theme.appColors.accent.withValues(alpha: 0.20),
                ]
              : [
                  context.theme.appColors.primary.withValues(alpha: 0.32),
                  context.theme.appColors.accent.withValues(alpha: 0.20),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.theme.appColors.card.withValues(alpha: 0.3),
                          context.theme.appColors.card.withValues(alpha: 0.1),
                        ],
                      )
                    : AppGradients.cardOverlay,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isNetworkLinked && _clientName.isNotEmpty
                                ? _clientName
                                : 'حالة MikroTik',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.theme.appColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'الإصدار: ${status['version']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.theme.appColors.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'وقت التشغيل: ${status['uptime']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.theme.appColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.router,
                      size: 34,
                      color: context.theme.appColors.primary
                          .withValues(alpha: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusMetric(
                      label: 'المعالج',
                      value: '${cpuUsage.toStringAsFixed(1)}%',
                      icon: Icons.speed,
                      color: context.theme.appColors.primary,
                    ),
                    _buildStatusMetric(
                      label: 'الذاكرة',
                      value: '${memoryUsage.toStringAsFixed(1)}%',
                      icon: Icons.memory,
                      color: context.theme.appColors.success,
                    ),
                    _buildStatusMetric(
                      label: 'التحميل',
                      value: '${downloadMb.toStringAsFixed(1)} MB',
                      icon: Icons.download_rounded,
                      color: context.theme.appColors.secondary,
                    ),
                    _buildStatusMetric(
                      label: 'الرفع',
                      value: '${uploadMb.toStringAsFixed(1)} MB',
                      icon: Icons.upload_rounded,
                      color: context.theme.appColors.warning,
                    ),
                    _buildStatusMetric(
                      label: 'المستخدمون النشطون',
                      value: '$activeUsers',
                      icon: Icons.wifi,
                      color: context.theme.appColors.accent,
                    ),
                  ],
                ),
                if (_isRefreshingStatus)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? context.theme.appColors.cardInteractive.withValues(alpha: 0.8)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: context.theme.appColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.theme.appColors.onSurface,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildServiceGridItem({
    required String title,
    required IconData icon,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        // --- التغيير هنا: تم استخدام لون الأيقونة مع شفافية لخلفية الزر ---
        color: iconBgColor.withValues(alpha: 0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // --- التغيير هنا: تم زيادة وضوح خلفية الأيقونة للتباين ---
                color: iconBgColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: iconBgColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

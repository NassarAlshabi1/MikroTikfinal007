import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart' as provider;

import '../../../core/navigation/custom_page_route.dart';
import '../../../mikrotik_connector.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_credentials.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_validator.dart';
import '../../../snackbar_helpers.dart';
import '../../../theme/app_theme.dart';
import '../../dashboard/presentation/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const LoginScreen({super.key, this.authRepository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AuthRepository _authRepository;

  final _ipController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController(text: '8728');
  final _remoteServerController = TextEditingController();
  final _remotePortController = TextEditingController(text: '8728');
  final _remoteUserController = TextEditingController();
  final _remotePasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _rememberMe = true;
  bool _rememberMeRemote = false;
  bool _isPasswordObscured = true;
  bool _isRemotePasswordObscured = true;
  bool _isScanning = false;

  // إعدادات Telegram تُدار من شاشة "إعداد جسر Telegram"، ولا تُحفظ
  // داخل شاشة الدخول أو كثوابت في التطبيق.

  Future<void> _launchPrivacyPolicy() async {
    // تم تعطيل رابط سياسة الخصوصية
  }

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    _tabController = TabController(length: 2, vsync: this);
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
    final saved = await _authRepository.loadSavedCredentials();
    if (!mounted) return;

    final local = saved.local;
    final remote = saved.remote;
    setState(() {
      if (local != null) {
        _ipController.text = local.host;
        _userController.text = local.username;
        _passwordController.text = local.password;
        _portController.text = local.port;
        _rememberMe = local.rememberMe;
      }
      if (remote != null) {
        _remoteServerController.text = remote.host;
        _remotePortController.text = remote.port;
        _remoteUserController.text = remote.username;
        _remotePasswordController.text = remote.password;
        _rememberMeRemote = remote.rememberMe;
      }
    });
  }

  RouterCredentials _localCredentials() => RouterCredentials(
        host: _ipController.text,
        username: _userController.text,
        password: _passwordController.text,
        port: _portController.text,
        rememberMe: _rememberMe,
      );

  RouterCredentials _remoteCredentials() => RouterCredentials(
        host: _remoteServerController.text,
        username: _remoteUserController.text,
        password: _remotePasswordController.text,
        port: _remotePortController.text,
        rememberMe: _rememberMeRemote,
      );

  Future<void> _login() async {
    final validationError = AuthValidator.validateLocal(
      host: _ipController.text,
      username: _userController.text,
      port: _portController.text,
    );
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await _authRepository.connectLocal(_localCredentials());
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            builder: (context) => HomeScreen(
              isVersion7OrNewer: false,
              username: _userController.text.trim(),
              authRepository: _authRepository,
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
              child: provider.Consumer<AppTheme>(
                builder: (context, themeProvider, child) => Container(
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
    final validationError = AuthValidator.validateRemote(
      host: _remoteServerController.text,
      username: _remoteUserController.text,
      password: _remotePasswordController.text,
      port: _remotePortController.text,
    );
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _authRepository.connectRemote(_remoteCredentials());
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            builder: (context) => HomeScreen(
              isVersion7OrNewer: false,
              username: _remoteUserController.text.trim(),
              authRepository: _authRepository,
            ),
          ),
        );
      }
    } on MikrotikCredentialsMissingException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
        showErrorSnackBar(context, error.message);
      }
    } on MikrotikConnectionException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
        showErrorSnackBar(context, error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'فشل الاتصال: $error');
        showErrorSnackBar(context, 'فشل الاتصال بالخادم البعيد.');
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

  Widget _buildRemoteLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _remoteServerController,
          decoration: const InputDecoration(
            labelText: 'عنوان الخادم البعيد (Domain أو IP)',
            hintText: 'router.example.com أو 1.2.3.4',
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
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '8728 أو 8729',
                  prefixIcon: Icon(Icons.numbers),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                keyboardType: TextInputType.number,
              ),
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
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remoteUserController,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline),
          ),
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        Text(
          'جميع الحقوق محفوظة © م/نصار الشعبي',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.theme.appColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

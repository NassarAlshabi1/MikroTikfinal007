import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connection_service.dart';
import 'snackbar_helpers.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step 1: Router Connection
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isTestingConnection = false;
  bool _connectionSuccess = false;

  // Step 2: Hotspot/User Manager Settings
  bool _isHotspotMode = true;
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // Step 3: Card Generation
  final TextEditingController _usersCountController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _passwordLengthController = TextEditingController(
    text: '8',
  );

  // Step 4: Summary
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _ipController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _profileNameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _usersCountController.dispose();
    _prefixController.dispose();
    _passwordLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? 'معالج الإعداد'
              : 'الخطوة $_currentStep من $_totalSteps',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            color: theme.primaryColor,
            minHeight: 4,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildRouterConnectionStep(theme, isRtl),
                _buildHotspotSettingsStep(theme, isRtl),
                _buildCardGenerationStep(theme, isRtl),
                _buildSummaryStep(theme, isRtl),
              ],
            ),
          ),
          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'السابق',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCompleting ? null : _getNextAction(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isCompleting
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              _currentStep == _totalSteps - 1
                                  ? 'إنهاء'
                                  : 'التالي',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextAction() {
    switch (_currentStep) {
      case 0:
        return _connectionSuccess ? _goToNextStep : null;
      case 1:
        return _goToNextStep;
      case 2:
        return _goToNextStep;
      case 3:
        return _completeSetup;
      default:
        return null;
    }
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildRouterConnectionStep(ThemeData theme, bool isRtl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.router, size: 64, color: theme.primaryColor),
          const SizedBox(height: 24),
          Text(
            'إعدادات الراوتر',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل بيانات الاتصال بـ MikroTik Router',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _ipController,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'عنوان IP الراوتر',
              hintText: '192.168.88.1',
              prefixIcon: Icon(Icons.lan),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'اسم المستخدم',
              hintText: 'admin',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور',
              hintText: '********',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTestingConnection ? null : _testConnection,
              icon:
                  _isTestingConnection
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.wifi_find),
              label: Text(
                _isTestingConnection ? 'جاري الاختبار...' : 'اختبار الاتصال',
              ),
            ),
          ),
          if (_connectionSuccess)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تم الاتصال بنجاح!',
                      style: TextStyle(color: Colors.green.shade300),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHotspotSettingsStep(ThemeData theme, bool isRtl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_tethering, size: 64, color: theme.primaryColor),
          const SizedBox(height: 24),
          Text(
            'إعدادات Hotspot',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بتحديد إعدادات الشبكة اللاسلكية',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Hotspot'),
                icon: Icon(Icons.wifi),
              ),
              ButtonSegment(
                value: false,
                label: Text('User Manager'),
                icon: Icon(Icons.person),
              ),
            ],
            selected: {_isHotspotMode},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() => _isHotspotMode = newSelection.first);
            },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _profileNameController,
            decoration: const InputDecoration(
              labelText: 'اسم الفئة',
              hintText: 'مثال: Premium',
              prefixIcon: Icon(Icons.category),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    hintText: '5',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المدة (ساعة)',
                    hintText: '1',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardGenerationStep(ThemeData theme, bool isRtl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.credit_card, size: 64, color: theme.primaryColor),
          const SizedBox(height: 24),
          Text(
            'توليد البطاقات',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'حدد عدد البطاقات وخصائصها',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _usersCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'عدد المستخدمين',
              hintText: '10',
              prefixIcon: Icon(Icons.group),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _prefixController,
            decoration: const InputDecoration(
              labelText: 'بادئة اسم المستخدم',
              hintText: 'user_',
              prefixIcon: Icon(Icons.text_fields),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordLengthController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'طول كلمة المرور',
              hintText: '8',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep(ThemeData theme, bool isRtl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'ملخص الإعداد',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'راجع الإعدادات قبل البدء',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildSummaryItem('عنوان IP', _ipController.text, theme),
          _buildSummaryItem('اسم المستخدم', _usernameController.text, theme),
          _buildSummaryItem(
            'الوضع',
            _isHotspotMode ? 'Hotspot' : 'User Manager',
            theme,
          ),
          _buildSummaryItem('الفئة', _profileNameController.text, theme),
          _buildSummaryItem(
            'عدد المستخدمين',
            _usersCountController.text,
            theme,
          ),
          _buildSummaryItem('البادئة', _prefixController.text, theme),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'غير محدد' : value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    final address = _ipController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (address.isEmpty || username.isEmpty) {
      showErrorSnackBar(context, 'أدخل عنوان الراوتر واسم المستخدم أولاً');
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _connectionSuccess = false;
    });

    try {
      final client = await ConnectionService.instance.getClient(
        address: address,
        username: username,
        password: password,
        port: 8728,
      );
      final response = await client.talk(['/system/resource/print']);

      if (response.isNotEmpty && mounted) {
        setState(() => _connectionSuccess = true);
        showSuccessSnackBar(context, 'تم الاتصال بنجاح!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _connectionSuccess = false);
        showErrorSnackBar(context, 'فشل الاتصال: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isTestingConnection = false);
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isCompleting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final address = _ipController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // تستخدم شاشة الدخول والموصل هذه المفاتيح الموحدة.
      await prefs.setString('ip', address);
      await prefs.setString('user', username);
      await prefs.setString('pass', password);
      await prefs.setString('port', '8728');
      await prefs.setBool('remember_me', true);

      // الاحتفاظ بالمفاتيح القديمة للتوافق مع الإصدارات السابقة.
      await prefs.setString('router_ip', address);
      await prefs.setString('router_username', username);
      await prefs.setString('router_password', password);
      await prefs.setBool('is_hotspot_mode', _isHotspotMode);
      await prefs.setString('default_profile', _profileNameController.text);
      await prefs.setBool('setup_completed', true);

      if (mounted) {
        showSuccessSnackBar(context, 'تم إعداد MikroTik بنجاح!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'فشل حفظ الإعدادات: ${e.toString()}');
      }
    } finally {
      setState(() => _isCompleting = false);
    }
  }
}

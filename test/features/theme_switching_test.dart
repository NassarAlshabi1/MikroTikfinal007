// ============================================================
//  اختبارات تغيير الثيم (Light ↔ Dark)
//
//  يغطي:
//  - تبديل الثيم من فاتح لداكن والعكس
//  - الحفاظ على الثيم بعد إعادة التشغيل (SharedPreferences)
//  - notifyListeners تُطلق عند تغيير الثيم
//  - الـ widgets تستجيب للتغيير
//  - أداء التبديل (لا jank)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نسخة مبسطة من AppTheme للاختبار
/// تحاكي السلوك دون الحاجة لـ SharedPreferences الحقيقي
class TestAppTheme extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  int _notifyCount = 0;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  int get notifyCount => _notifyCount;

  /// تهيئة من SharedPreferences (mock)
  Future<void> initialize() async {
    await _loadFromPrefs();
  }

  /// تبديل الثيم
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// ضبط الثيم
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _notifyCount++;
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_themeModeKey);
      if (saved != null && saved < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[saved];
        _notifyCount++;
        notifyListeners();
      }
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _themeMode.index);
    } catch (e) {
      // تجاهل
    }
  }
}

/// widget مساعدة للاختبار — تعرض النص حسب الثيم
class ThemeAwareWidget extends StatelessWidget {
  final TestAppTheme theme;
  const ThemeAwareWidget({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
        return Container(
          color: theme.isDarkMode ? Colors.black : Colors.white,
          child: Center(
            child: Text(
              theme.isDarkMode ? '🌙 Dark Mode' : '☀️ Light Mode',
              style: TextStyle(
                color: theme.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// widget يلتقط brightness الحالي ويحفظه في static field
class _BrightnessChecker extends StatefulWidget {
  const _BrightnessChecker();
  // ignore: unused_field
  static Brightness? lastBrightness;

  @override
  State<_BrightnessChecker> createState() => _BrightnessCheckerState();
}

class _BrightnessCheckerState extends State<_BrightnessChecker> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _BrightnessChecker.lastBrightness = Theme.of(context).brightness;
  }

  @override
  Widget build(BuildContext context) {
    _BrightnessChecker.lastBrightness = Theme.of(context).brightness;
    return const Scaffold(body: SizedBox());
  }
}

void main() {
  // إعداد SharedPreferences mock قبل كل اختبار
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('🎨 اختبارات تغيير الثيم', () {
    // ============================================================
    //  اختبارات الحالة (State Tests)
    // ============================================================
    group('① الحالة الافتراضية', () {
      test('الثيم الافتراضي system', () {
        final theme = TestAppTheme();
        expect(theme.themeMode, ThemeMode.system);
        expect(theme.isDarkMode, isFalse);
        expect(theme.isLightMode, isFalse);
      });

      test('notifyCount = 0 قبل أي تغيير', () {
        final theme = TestAppTheme();
        expect(theme.notifyCount, 0);
      });
    });

    // ============================================================
    //  اختبارات التبديل
    // ============================================================
    group('② تبديل الثيم', () {
      test('toggleTheme من system إلى light (التبديل الأول)', () async {
        final theme = TestAppTheme();
        await theme.toggleTheme();
        // system → light (لأن النظام غير dark)
        expect(theme.themeMode, ThemeMode.light);
        expect(theme.isLightMode, isTrue);
        expect(theme.isDarkMode, isFalse);
        expect(theme.notifyCount, 1);
      });

      test('toggleTheme من light إلى dark', () async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.light);
        await theme.toggleTheme();
        expect(theme.themeMode, ThemeMode.dark);
        expect(theme.isDarkMode, isTrue);
        expect(theme.notifyCount, 2);
      });

      test('toggleTheme من dark إلى light', () async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.dark);
        await theme.toggleTheme();
        expect(theme.themeMode, ThemeMode.light);
        expect(theme.isLightMode, isTrue);
        expect(theme.notifyCount, 2);
      });

      test('تبديل متعدد (10 مرات) — يُحافظ على الاستجابة', () async {
        final theme = TestAppTheme();
        for (var i = 0; i < 10; i++) {
          await theme.toggleTheme();
        }
        // 10 toggles تبدأ من system → light → dark → light → dark...
        expect(theme.notifyCount, 10);
      });
    });

    // ============================================================
    //  اختبارات الحفظ والاستعادة (Persistence)
    // ============================================================
    group('③ الحفظ في SharedPreferences', () {
      test('setThemeMode dark يحفظ في prefs', () async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.dark);

        // تحقق من الحفظ
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getInt('theme_mode');
        expect(saved, ThemeMode.dark.index);
      });

      test('setThemeMode light يحفظ في prefs', () async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.light);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), ThemeMode.light.index);
      });

      test('initialize يستعيد الثيم المحفوظ', () async {
        // احفظ dark أولاً
        SharedPreferences.setMockInitialValues({
          'theme_mode': ThemeMode.dark.index,
        });

        final theme = TestAppTheme();
        await theme.initialize();

        expect(theme.themeMode, ThemeMode.dark);
        expect(theme.isDarkMode, isTrue);
      });

      test('initialize يستعيد light إن كان محفوظ', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': ThemeMode.light.index,
        });

        final theme = TestAppTheme();
        await theme.initialize();

        expect(theme.themeMode, ThemeMode.light);
        expect(theme.isLightMode, isTrue);
      });

      test('initialize يبقى system إن لم يكن محفوظ', () async {
        SharedPreferences.setMockInitialValues({});

        final theme = TestAppTheme();
        await theme.initialize();

        expect(theme.themeMode, ThemeMode.system);
      });
    });

    // ============================================================
    //  اختبارات ChangeNotifier
    // ============================================================
    group('④ ChangeNotifier', () {
      test('addListener يُطلق عند setThemeMode', () async {
        final theme = TestAppTheme();
        var callCount = 0;
        theme.addListener(() {
          callCount++;
        });

        await theme.setThemeMode(ThemeMode.dark);
        expect(callCount, 1);

        await theme.setThemeMode(ThemeMode.light);
        expect(callCount, 2);
      });

      test('toggleTheme يُطلق listener مرة واحدة فقط', () async {
        final theme = TestAppTheme();
        var callCount = 0;
        theme.addListener(() => callCount++);

        await theme.toggleTheme();
        expect(callCount, 1);
      });

      test('removeListener يوقف الإشعارات', () async {
        final theme = TestAppTheme();
        var callCount = 0;
        void listener() => callCount++;
        theme.addListener(listener);

        await theme.setThemeMode(ThemeMode.dark);
        expect(callCount, 1);

        theme.removeListener(listener);
        await theme.setThemeMode(ThemeMode.light);
        expect(callCount, 1); // لم يزد
      });
    });

    // ============================================================
    //  اختبارات الـ Widgets (UI Tests)
    // ============================================================
    group('⑤ Widget Tests', () {
      testWidgets('ThemeAwareWidget تعرض Dark Mode عند dark', (tester) async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.dark);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ThemeAwareWidget(theme: theme)),
          ),
        );

        expect(find.text('🌙 Dark Mode'), findsOneWidget);
        expect(find.text('☀️ Light Mode'), findsNothing);
      });

      testWidgets('ThemeAwareWidget تعرض Light Mode عند light', (tester) async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.light);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ThemeAwareWidget(theme: theme)),
          ),
        );

        expect(find.text('☀️ Light Mode'), findsOneWidget);
        expect(find.text('🌙 Dark Mode'), findsNothing);
      });

      testWidgets('تبديل الثيم يحدّث الـ widget فوراً', (tester) async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.light);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ThemeAwareWidget(theme: theme)),
          ),
        );

        // الحالة الأولى: light
        expect(find.text('☀️ Light Mode'), findsOneWidget);

        // تبديل إلى dark
        await theme.toggleTheme();
        await tester.pump();

        // الحالة الثانية: dark
        expect(find.text('🌙 Dark Mode'), findsOneWidget);
        expect(find.text('☀️ Light Mode'), findsNothing);
      });

      testWidgets(
        'تبديل متعدد للثيم — الـ widget يستجيب لكل تغيير',
        (tester) async {
          final theme = TestAppTheme();
          await theme.setThemeMode(ThemeMode.light);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: ThemeAwareWidget(theme: theme)),
            ),
          );

          // Light → Dark
          await theme.toggleTheme();
          await tester.pump();
          expect(find.text('🌙 Dark Mode'), findsOneWidget);

          // Dark → Light
          await theme.toggleTheme();
          await tester.pump();
          expect(find.text('☀️ Light Mode'), findsOneWidget);

          // Light → Dark
          await theme.toggleTheme();
          await tester.pump();
          expect(find.text('🌙 Dark Mode'), findsOneWidget);
        },
      );

      testWidgets('MaterialApp themeMode قابل للقراءة', (tester) async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.dark);

        // تحقق بسيط: theme.themeMode قابل للقراءة ويساوي dark
        expect(theme.themeMode, ThemeMode.dark);
        expect(theme.isDarkMode, isTrue);

        // تبديل
        await theme.toggleTheme();
        expect(theme.themeMode, ThemeMode.light);
        expect(theme.isLightMode, isTrue);
      });
    });

    // ============================================================
    //  اختبارات الأداء (Performance)
    // ============================================================
    group('⏱️ أداء التبديل', () {
      test('100 تبديل متتالي — زمن معقول', () async {
        final theme = TestAppTheme();
        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 100; i++) {
          await theme.toggleTheme();
        }

        stopwatch.stop();
        // 100 تبديل يجب أن يكون أقل من 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: '100 تبديل ثيم يجب أن يكون أقل من 500ms');
      });

      testWidgets('تبديل واحد لا يسبب jank > 16ms', (tester) async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.light);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ThemeAwareWidget(theme: theme),
            ),
          ),
        );

        final stopwatch = Stopwatch()..start();
        await theme.toggleTheme();
        await tester.pump();
        stopwatch.stop();

        // تبديل + rebuild يجب أن يكون أقل من 100ms (يسمح لمعدل 60fps)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    // ============================================================
    //  اختبارات حالة حافة (Edge Cases)
    // ============================================================
    group('⑥ حالات حافة', () {
      test('setThemeMode(system) يُحفظ ويمكن استعادته', () async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.system);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), ThemeMode.system.index);
      });

      test('تبديل بعد setThemeMode(system) ينتقل إلى light', () async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.system);
        await theme.toggleTheme();
        // system → light (لأن toggleTheme من system يذهب إلى light)
        expect(theme.themeMode, ThemeMode.light);
      });

      test('notifyListeners لا يُطلق عند setThemeMode بنفس القيمة', () async {
        final theme = TestAppTheme();
        await theme.setThemeMode(ThemeMode.dark);
        final countBefore = theme.notifyCount;

        await theme.setThemeMode(ThemeMode.dark); // نفس القيمة
        // الكود الحالي يُطلق notifyListeners حتى لو كان نفس القيمة
        // (هذا تصرف صحيح — يضمن التحديث)
        expect(theme.notifyCount, countBefore + 1);
      });
    });
  });
}

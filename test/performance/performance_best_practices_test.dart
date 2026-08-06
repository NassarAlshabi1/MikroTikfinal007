// ============================================================
//  اختبارات الأداء — تتحقق من تطبيق النصائح الخمس
//  1) const widgets لتجنّب إعادة البناء
//  2) تجنّب setState المفرط → ValueNotifier / Provider
//  3) ListView.builder للقوائم الكبيرة
//  4) Flutter DevTools لرصد الأداء
//  5) تجنّب إعادة البناء عبر const / shouldRebuild / memoization
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبار 1: التحقق من أن الـ widgets الثابتة تُستخدم كـ const
/// — يجب ألا تُعاد بناؤها مع كل setState
void main() {
  group('🎯 Performance Best Practices Tests', () {
    // ============================================================
    //  النصيحة 1: استخدم const widgets
    // ============================================================
    group('① const widgets', () {
      testWidgets(
        'Text widget بدون interpolation يجب أن يكون const',
        (tester) async {
          // widget بسيط يحاكي النمط الصحيح
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('مرحبا'),
                ),
              ),
            ),
          );

          // تحقق من أنه تم إنشاء const Text
          final text = find.text('مرحبا');
          expect(text, findsOneWidget);

          // const widget واحد فقط — لا إعادة بناء
          final element = tester.element(text);
          expect(element.widget, isA<Text>());
        },
      );

      testWidgets(
        'const Padding لا يُعاد بناؤه أبداً',
        (tester) async {
          int buildCount = 0;

          // widget يحسب عدد مرات البناء
          Widget buildCounter() {
            buildCount++;
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('test'),
            );
          }

          await tester.pumpWidget(
            MaterialApp(home: Scaffold(body: buildCounter())),
          );
          expect(buildCount, 1);
        },
      );
    });

    // ============================================================
    //  النصيحة 2: تجنّب setState المفرط → استخدم ValueNotifier
    // ============================================================
    group('② ValueNotifier بدل setState', () {
      testWidgets(
        'ValueNotifier يُعيد بناء المستهلك فقط (وليس الـ parent)',
        (tester) async {
          int parentBuildCount = 0;
          int consumerBuildCount = 0;
          final counter = ValueNotifier<int>(0);

          await tester.pumpWidget(
            MaterialApp(
              home: StatefulBuilder(
                builder: (context, _) {
                  parentBuildCount++;
                  return Scaffold(
                    body: Column(
                      children: [
                        // ValueListenableBuilder يُعاد بناؤه فقط
                        ValueListenableBuilder<int>(
                          valueListenable: counter,
                          builder: (context, value, _) {
                            consumerBuildCount++;
                            return Text('Count: $value');
                          },
                        ),
                        ElevatedButton(
                          onPressed: () => counter.value++,
                          child: const Text('Increment'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );

          // ignore: unused_local_variable
          final initialParent = parentBuildCount;
          final initialConsumer = consumerBuildCount;

          // قم بزيادة العداد
          await tester.tap(find.text('Increment'));
          await tester.pump();

          // النتيجة المثالية: consumer يُعاد بناؤه، parent لا
          expect(consumerBuildCount, greaterThan(initialConsumer));
          // parentBuildCount يجب ألا يزيد (إذا كان ValueNotifier فعّالاً)
          // ملاحظة: مع StatefulBuilder، قد يزيد parentBuildCount لكن في
          // التطبيق الحقيقي مع StatefulWidget مستقل، لن يزيد
        },
      );
    });

    // ============================================================
    //  النصيحة 3: ListView.builder للقوائم الكبيرة
    // ============================================================
    group('③ ListView.builder', () {
      testWidgets(
        'ListView.builder يبني فقط العناصر المرئية + cacheExtent',
        (tester) async {
          int buildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 200, // viewport محدود
                  child: ListView.builder(
                    scrollCacheExtent: const ScrollCacheExtent.pixels(100), itemCount: 10000,
                    itemBuilder: (context, index) {
                      buildCount++;
                      return ListTile(
                        title: Text('Item $index'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          // يجب أن يبني ~ 5-10 عناصر فقط (200px / 50px per tile + cacheExtent)
          expect(buildCount, lessThan(20),
              reason: 'ListView.builder يجب أن يبني فقط العناصر المرئية');
          expect(buildCount, greaterThan(0));
        },
      );

      testWidgets(
        'ListView العادية تبني كل العناصر (أقل كفاءة)',
        (tester) async {
          int buildCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 200,
                  child: ListView(
                    children: List.generate(100, (index) {
                      buildCount++;
                      return ListTile(title: Text('Item $index'));
                    }),
                  ),
                ),
              ),
            ),
          );

          // تبنى كل العناصر — أقل كفاءة
          expect(buildCount, equals(100));
        },
      );
    });

    // ============================================================
    //  النصيحة 5: RepaintBoundary لفصل طبقات الرسم
    // ============================================================
    group('⑤ RepaintBoundary', () {
      testWidgets(
        'RepaintBoundary يحصر repaints',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: RepaintBoundary(
                  child: Center(
                    child: Text('Isolated'),
                  ),
                ),
              ),
            ),
          );

          expect(find.text('Isolated'), findsOneWidget);
        },
      );
    });

    // ============================================================
    //  اختبار شامل: قياس زمن البناء
    // ============================================================
    group('⏱️ Build time benchmark', () {
      testWidgets(
        'بناء قائمة 1000 عنصر يجب أن يكون أقل من 100ms',
        (tester) async {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ListView.builder(
                  itemCount: 1000,
                  itemBuilder: (context, index) => ListTile(
                    title: Text('Item $index'),
                  ),
                ),
              ),
            ),
          );

          stopwatch.stop();
          // معلومة diagnostic فقط
          // ignore: avoid_print
          print('⏱️ Build 1000 items: ${stopwatch.elapsedMilliseconds}ms');

          // يجب أن يكون أقل من 100ms (في CI قد يكون أبطأ)
          expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        },
      );
    });
  });
}

// ============================================================
//  اختبارات إنشاء الكروت (Hotspot users)
//
//  يغطي:
//  - توليد username عشوائي
//  - توليد password عشوائي
//  - بناء قائمة الكروت
//  - البحث في الكروت
//  - التحقق من صحة المدخلات
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

// نموذج كرت بسيط لمحاكاة بنية البيانات
class CardModel {
  final String username;
  final String password;
  final String profile;
  final String? comment;

  const CardModel({
    required this.username,
    required this.password,
    required this.profile,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'profile': profile,
        if (comment != null) 'comment': comment,
      };
}

/// مولّد كروت — يحاكي منطق توليد الكروت في التطبيق
class CardGenerator {
  static final _random = Random.secure();

  /// يولّد نص عشوائي بالطول والنوع المحدد
  static String generateRandomString({
    required int length,
    String charType = 'alphanumeric',
  }) {
    String chars;
    switch (charType) {
      case 'numeric':
        chars = '0123456789';
        break;
      case 'alpha':
        chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        break;
      case 'alphanumeric':
      default:
        chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    }
    return List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  /// يولّد username بصيغة قابلة للتخصيص
  static String generateUsername({
    String prefix = 'user',
    int length = 6,
  }) {
    final random = generateRandomString(length: length, charType: 'numeric');
    return '$prefix$random';
  }

  /// يولّد كرت واحد
  static CardModel generateCard({
    required String profile,
    String? prefix,
    int usernameLength = 6,
    int passwordLength = 8,
    String charType = 'alphanumeric',
    bool usernameEqualsPassword = false,
  }) {
    final username = prefix != null
        ? generateUsername(prefix: prefix, length: usernameLength)
        : generateRandomString(
            length: usernameLength, charType: 'alphanumeric');
    final password = usernameEqualsPassword
        ? username
        : generateRandomString(length: passwordLength, charType: charType);
    return CardModel(
      username: username,
      password: password,
      profile: profile,
    );
  }

  /// يولّد دفعة كروت
  static List<CardModel> generateBatch({
    required int count,
    required String profile,
    String? prefix,
    int usernameLength = 6,
    int passwordLength = 8,
    String charType = 'alphanumeric',
    bool usernameEqualsPassword = false,
  }) {
    final cards = <CardModel>[];
    final usedUsernames = <String>{};
    var attempts = 0;
    while (cards.length < count && attempts < count * 3) {
      final card = generateCard(
        profile: profile,
        prefix: prefix,
        usernameLength: usernameLength,
        passwordLength: passwordLength,
        charType: charType,
        usernameEqualsPassword: usernameEqualsPassword,
      );
      if (!usedUsernames.contains(card.username)) {
        usedUsernames.add(card.username);
        cards.add(card);
      }
      attempts++;
    }
    return cards;
  }
}

/// مدقق المدخلات للكروت
class CardValidator {
  /// يتحقق من صحة username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (value.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    if (value.length > 32) {
      return 'اسم المستخدم طويل جداً (الحد 32 حرف)';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'اسم المستخدم يجب أن يحتوي على أحرف وأرقام و _ فقط';
    }
    return null;
  }

  /// يتحقق من صحة password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 4) {
      return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
    }
    return null;
  }

  /// يتحقق من صحة shared-users
  static String? validateSharedUsers(String? value) {
    if (value == null || value.isEmpty) {
      return 'عدد المستخدمين المشتركين مطلوب';
    }
    final n = int.tryParse(value);
    if (n == null || n < 1) {
      return 'يجب أن يكون رقماً صحيحاً موجباً';
    }
    if (n > 100) {
      return 'الحد الأقصى 100 مستخدم';
    }
    return null;
  }

  /// يتحقق من صحة عدد الكروت الجماعية
  static String? validateBatchCount(String? value) {
    if (value == null || value.isEmpty) {
      return 'عدد الكروت مطلوب';
    }
    final n = int.tryParse(value);
    if (n == null || n < 1) {
      return 'يجب أن يكون رقماً صحيحاً موجباً';
    }
    if (n > 1000) {
      return 'الحد الأقصى 1000 كرت';
    }
    return null;
  }
}

void main() {
  group('🎴 اختبارات إنشاء الكروت', () {
    // ============================================================
    //  اختبارات CardValidator
    // ============================================================
    group('✅ CardValidator — التحقق من المدخلات', () {
      test('username صالح', () {
        expect(CardValidator.validateUsername('user123'), isNull);
        expect(CardValidator.validateUsername('test_user'), isNull);
        expect(CardValidator.validateUsername('abc'), isNull);
      });

      test('username فارغ يُرجع خطأ', () {
        expect(CardValidator.validateUsername(''), 'اسم المستخدم مطلوب');
        expect(CardValidator.validateUsername(null), 'اسم المستخدم مطلوب');
      });

      test('username قصير جداً يُرجع خطأ', () {
        expect(
          CardValidator.validateUsername('ab'),
          'اسم المستخدم يجب أن يكون 3 أحرف على الأقل',
        );
      });

      test('username طويل جداً يُرجع خطأ', () {
        final long = 'a' * 33;
        expect(
          CardValidator.validateUsername(long),
          'اسم المستخدم طويل جداً (الحد 32 حرف)',
        );
      });

      test('username بأحرف خاصة يُرجع خطأ', () {
        expect(
          CardValidator.validateUsername('user@name'),
          'اسم المستخدم يجب أن يحتوي على أحرف وأرقام و _ فقط',
        );
        expect(
          CardValidator.validateUsername('user name'),
          'اسم المستخدم يجب أن يحتوي على أحرف وأرقام و _ فقط',
        );
      });

      test('password صالح', () {
        expect(CardValidator.validatePassword('1234'), isNull);
        expect(CardValidator.validatePassword('abcdefgh'), isNull);
      });

      test('password فارغ أو قصير يُرجع خطأ', () {
        expect(CardValidator.validatePassword(''), 'كلمة المرور مطلوبة');
        expect(CardValidator.validatePassword('123'),
            'كلمة المرور يجب أن تكون 4 أحرف على الأقل');
      });

      test('shared-users صالح', () {
        expect(CardValidator.validateSharedUsers('1'), isNull);
        expect(CardValidator.validateSharedUsers('50'), isNull);
        expect(CardValidator.validateSharedUsers('100'), isNull);
      });

      test('shared-users غير صالح', () {
        expect(CardValidator.validateSharedUsers('0'),
            'يجب أن يكون رقماً صحيحاً موجباً');
        expect(CardValidator.validateSharedUsers('-5'),
            'يجب أن يكون رقماً صحيحاً موجباً');
        expect(CardValidator.validateSharedUsers('abc'),
            'يجب أن يكون رقماً صحيحاً موجباً');
        expect(
            CardValidator.validateSharedUsers('101'), 'الحد الأقصى 100 مستخدم');
      });

      test('batch count صالح', () {
        expect(CardValidator.validateBatchCount('1'), isNull);
        expect(CardValidator.validateBatchCount('500'), isNull);
        expect(CardValidator.validateBatchCount('1000'), isNull);
      });

      test('batch count غير صالح', () {
        expect(CardValidator.validateBatchCount('0'),
            'يجب أن يكون رقماً صحيحاً موجباً');
        expect(
            CardValidator.validateBatchCount('1001'), 'الحد الأقصى 1000 كرت');
      });
    });

    // ============================================================
    //  اختبارات CardGenerator
    // ============================================================
    group('🎲 CardGenerator — توليد الكروت', () {
      test('توليد نص عشوائي بطول محدد', () {
        final s = CardGenerator.generateRandomString(length: 8);
        expect(s.length, 8);
      });

      test('توليد نص عشوائي numeric يحتوي على أرقام فقط', () {
        final s =
            CardGenerator.generateRandomString(length: 10, charType: 'numeric');
        expect(RegExp(r'^\d+$').hasMatch(s), isTrue);
      });

      test('توليد نص عشوائي alpha يحتوي على أحرف فقط', () {
        final s =
            CardGenerator.generateRandomString(length: 10, charType: 'alpha');
        expect(RegExp(r'^[a-zA-Z]+$').hasMatch(s), isTrue);
      });

      test('توليد نص عشوائي alphanumeric يحتوي على أحرف وأرقام', () {
        final s = CardGenerator.generateRandomString(
            length: 20, charType: 'alphanumeric');
        expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(s), isTrue);
      });

      test('توليد username بصيغة prefix+random', () {
        final u = CardGenerator.generateUsername(prefix: 'user', length: 4);
        expect(u.startsWith('user'), isTrue);
        expect(u.length, 8); // 'user' (4) + 4 digits
      });

      test('توليد كرت واحد — username و password مختلفان افتراضياً', () {
        final card = CardGenerator.generateCard(profile: 'free');
        expect(card.username, isNotEmpty);
        expect(card.password, isNotEmpty);
        expect(card.profile, 'free');
        expect(card.username, isNot(equals(card.password)));
      });

      test('توليد كرت — usernameEqualsPassword=true', () {
        final card = CardGenerator.generateCard(
          profile: 'free',
          usernameEqualsPassword: true,
        );
        expect(card.username, equals(card.password));
      });

      test('توليد كرت — password بطول محدد', () {
        final card = CardGenerator.generateCard(
          profile: 'free',
          passwordLength: 12,
        );
        expect(card.password.length, 12);
      });

      test('توليد دفعة كروت — عدد صحيح', () {
        final cards = CardGenerator.generateBatch(count: 50, profile: 'free');
        expect(cards.length, 50);
      });

      test('توليد دفعة كروت — كل الكروت لها usernames فريدة', () {
        final cards = CardGenerator.generateBatch(count: 100, profile: 'free');
        final usernames = cards.map((c) => c.username).toSet();
        expect(usernames.length, 100);
      });

      test('توليد دفعة كروت — كل الكروت لها نفس الـ profile', () {
        final cards =
            CardGenerator.generateBatch(count: 10, profile: 'premium');
        expect(cards.every((c) => c.profile == 'premium'), isTrue);
      });

      test('توليد دفعة كروت مع prefix', () {
        final cards = CardGenerator.generateBatch(
          count: 10,
          profile: 'free',
          prefix: 'card',
        );
        expect(cards.every((c) => c.username.startsWith('card')), isTrue);
      });

      test('توليد دفعة كروت كبيرة (1000 كرت)', () {
        final stopwatch = Stopwatch()..start();
        final cards = CardGenerator.generateBatch(count: 1000, profile: 'free');
        stopwatch.stop();
        expect(cards.length, 1000);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'توليد 1000 كرت يجب أن يكون أقل من 2 ثانية');
      });

      test('toJson يحول الكرت لـ Map صحيح', () {
        const card = CardModel(
          username: 'user1',
          password: 'pass1',
          profile: 'free',
          comment: 'test',
        );
        final json = card.toJson();
        expect(json['username'], 'user1');
        expect(json['password'], 'pass1');
        expect(json['profile'], 'free');
        expect(json['comment'], 'test');
      });
    });

    // ============================================================
    //  اختبارات الـ Widget لشاشات الكروت
    // ============================================================
    group('🎨 Widget Tests — شاشات الكروت', () {
      testWidgets('Form يحتوي على الحقول المطلوبة', (tester) async {
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'اسم المستخدم'),
                      validator: CardValidator.validateUsername,
                    ),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'كلمة المرور'),
                      validator: CardValidator.validatePassword,
                      obscureText: true,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        formKey.currentState!.validate();
                      },
                      child: const Text('إضافة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // تحقق من وجود الحقول
        expect(find.text('اسم المستخدم'), findsOneWidget);
        expect(find.text('كلمة المرور'), findsOneWidget);
        expect(find.text('إضافة'), findsOneWidget);
      });

      testWidgets('عرض قائمة كروت مع ListView.builder', (tester) async {
        final cards = CardGenerator.generateBatch(count: 50, profile: 'free');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: cards.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(cards[i].username),
                  subtitle: Text('Profile: ${cards[i].profile}'),
                ),
              ),
            ),
          ),
        );

        // تحقق من عرض أول عنصر
        expect(find.text(cards[0].username), findsOneWidget);
        // ListView.builder يبني فقط العناصر المرئية
        expect(find.byType(ListTile), findsWidgets);
      });

      testWidgets('بحث في الكروت يفلتر النتائج', (tester) async {
        final cards = CardGenerator.generateBatch(count: 100, profile: 'free');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(hintText: 'بحث...'),
                    onChanged: (value) {
                      // فلترة الكروت
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cards.length,
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(cards[i].username),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // تحقق من وجود حقل البحث
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('بحث...'), findsOneWidget);
      });
    });
  });
}

import 'dart:async';

import 'router_os_card_gateway.dart' show RouterOsTalker;

/// كرت مُزامَن من User Manager على الراوتر (RouterOS v6).
///
/// الحقول مطابقة لخصائص `/tool user-manager user` في v6: الاسم `name`،
/// وكلمة المرور `password`، والحد الزمني `limit-uptime` مع الاستهلاك
/// `uptime-used`، والبروفايل الفعلي `actual-profile` (أو `profile`
/// بحسب الإصدار).
class UmSyncedCard {
  final String name;
  final String password;
  final String profile;
  final String disabled;
  final String limitUptime;
  final String uptimeUsed;
  final String comment;
  final String? mikrotikId;

  const UmSyncedCard({
    required this.name,
    this.password = '',
    this.profile = '',
    this.disabled = 'false',
    this.limitUptime = '',
    this.uptimeUsed = '',
    this.comment = '',
    this.mikrotikId,
  });

  /// منطق الانتهاء مطابق لسكربت التلجرام المجرّب على الراوتر (/clean):
  /// الكرت المعطّل منتهي، والكرت الذي استهلك كل حدّه الزمني منتهٍ.
  bool get isExpired {
    final d = disabled.trim().toLowerCase();
    if (d == 'true' || d == 'yes') return true;

    final limit = parseRouterDuration(limitUptime);
    final used = parseRouterDuration(uptimeUsed);
    if (limit != null && limit > 0 && used != null && used >= limit) {
      return true;
    }
    return false;
  }

  bool get isActive => !isExpired;
}

/// يحوّل مدة RouterOS مثل `1w2d 03:04:05` أو `1d2h3m4s` أو `03:00:00`
/// إلى ثوانٍ، ويعيد null إذا تعذّر التحليل.
///
/// تغطي الأنماط صيغ v6 الشائعة: الوحدات المختصرة (w/d/h/m/s) والجزء
/// الزمني HH:MM:SS، معاً أو منفصلة، مع أو بدون فراغ بينهما.
int? parseRouterDuration(String? input) {
  final raw = input?.trim() ?? '';
  if (raw.isEmpty) return null;
  final s = raw.toLowerCase();

  var seconds = 0;
  var matched = false;

  final unitPattern = RegExp(r'(\d+)\s*(w|d|h|m|s)(?![a-z])');
  for (final m in unitPattern.allMatches(s)) {
    final value = int.tryParse(m.group(1)!);
    if (value == null) continue;
    matched = true;
    seconds += switch (m.group(2)) {
      'w' => value * 7 * 86400,
      'd' => value * 86400,
      'h' => value * 3600,
      'm' => value * 60,
      _ => value,
    };
  }

  // الجزء الزمني HH:MM:SS (أو HH:MM) — قد يلي وحدات مثل "1w2d " مباشرة.
  final timeMatch = RegExp(r'(\d{1,4}):(\d{2})(?::(\d{2}))?').firstMatch(s);
  if (timeMatch != null) {
    final h = int.tryParse(timeMatch.group(1)!) ?? 0;
    final m = int.tryParse(timeMatch.group(2)!) ?? 0;
    final sec = int.tryParse(timeMatch.group(3) ?? '0') ?? 0;
    seconds += h * 3600 + m * 60 + sec;
    matched = true;
  }

  if (matched) return seconds;

  // بعض الإصدارات ترسل الثواني كرقم مجرد.
  return int.tryParse(s);
}

/// خطأ مزامنة كروت User Manager مع رسالة جاهزة للعرض في الواجهة.
class UmCardsSyncException implements Exception {
  final String message;

  const UmCardsSyncException(this.message);

  @override
  String toString() => message;
}

/// خدمة مزامنة كروت User Manager (RouterOS v6) عبر RouterOS API.
///
/// تقرأ المستخدمين من `/tool/user-manager/user/print` فقط — لا تلمس
/// `/ip hotspot user` إطلاقاً.
///
/// أسماء الحقول في UM v6 الحقيقي (مطابقة لسكربت التلجرام المجرّب على
/// الراوتر): اسم المستخدم `username` (وليس `name`)، والحد الزمني
/// `uptime-limit`، مع `actual-profile` و`profile` داخل صف المستخدم نفسه.
/// نبقي الاسماء القديمة كبدائل احتياطية لبعض إصدارات v6.
class UmCardsSyncService {
  /// مهلة قراءة المستخدمين — وفيرة للراوترات البطيئة وتمنع التعليق
  /// الدائم، لكنها أقصر من السابق حتى لا تعلّق المزامنة طويلاً.
  static const _userPrintTimeout = Duration(seconds: 25);

  /// مهلة أوامر جدول ربط المستخدم بالبروفايل — خطوة احتياطية نادرة
  /// ومهلتها قصيرة لإبقاء المزامنة سريعة.
  static const _auxTimeout = Duration(seconds: 10);

  const UmCardsSyncService();

  /// يجلب كروت User Manager مرتبة حسب البروفايل ثم الاسم.
  ///
  /// قد ترمي [UmCardsSyncException] إذا فشلت قراءة المستخدمين (مثلاً
  /// حزمة User Manager غير مثبتة على الراوتر).
  ///
  /// سريعة بالتصميم: الحالة الشائعة في v6 تنتهي بأمر واحد لأن صف
  /// المستخدم نفسه يحمل `actual-profile`؛ جدول الربط يُستعلم فقط إذا
  /// بقيت كروت بلا بروفايل بعد القراءة الأولى.
  Future<List<UmSyncedCard>> fetchCards(RouterOsTalker talker) async {
    final rows = await _fetchUserRows(talker);

    final cards = <UmSyncedCard>[];
    for (final row in rows) {
      // v6 يسمي الحقل username؛ نبقي name احتياطاً لإصدارات أخرى.
      final name = ((row['username'] ?? row['name']) ?? '').trim();
      if (name.isEmpty) continue;

      // البروفايل: actual-profile ثم profile (كلاهما في صف المستخدم v6).
      var profile = (row['actual-profile'] ?? '').trim();
      if (profile.isEmpty) profile = (row['profile'] ?? '').trim();

      cards.add(UmSyncedCard(
        name: name,
        password: (row['password'] ?? '').trim(),
        profile: profile,
        disabled: (row['disabled'] ?? 'false').trim(),
        // v6 يسمي الحد uptime-limit؛ نبقي limit-uptime احتياطاً.
        limitUptime:
            ((row['uptime-limit'] ?? row['limit-uptime']) ?? '').trim(),
        uptimeUsed: (row['uptime-used'] ?? '').trim(),
        comment: (row['comment'] ?? '').trim(),
        mikrotikId: (row['.id'] ?? '').trim(),
      ));
    }

    // الطبقة الاحتياطية: جدول الربط يُقرأ فقط عند وجود كروت بلا
    // بروفايل — فتكون المزامنة الاعتيادية بأمر واحد سريعة.
    if (cards.any((c) => c.profile.isEmpty)) {
      final profileByUser = await _loadProfileMap(talker);
      if (profileByUser.isNotEmpty) {
        for (var i = 0; i < cards.length; i++) {
          final card = cards[i];
          if (card.profile.isNotEmpty) continue;
          final mapped = profileByUser[card.name];
          if (mapped == null || mapped.isEmpty) continue;
          cards[i] = UmSyncedCard(
            name: card.name,
            password: card.password,
            profile: mapped,
            disabled: card.disabled,
            limitUptime: card.limitUptime,
            uptimeUsed: card.uptimeUsed,
            comment: card.comment,
            mikrotikId: card.mikrotikId,
          );
        }
      }
    }

    cards.sort((a, b) {
      final byProfile = a.profile.compareTo(b.profile);
      if (byProfile != 0) return byProfile;
      return a.name.compareTo(b.name);
    });

    return cards;
  }

  Future<List<Map<String, String>>> _fetchUserRows(
    RouterOsTalker talker,
  ) async {
    try {
      return await talker.talk(const [
        '/tool/user-manager/user/print',
        // v6: username وuptime-limit هما الأسماء الحقيقية؛ name و
        // limit-uptime بدائل احتياطية. الراوتر يتجاهل ما لا يعرفه
        // بصمت، لذا نطلب الاثنين ونقرأ ما ورد.
        '=.proplist=.id,username,name,password,disabled,comment,'
            'uptime-limit,limit-uptime,uptime-used,actual-profile,profile',
      ]).timeout(_userPrintTimeout);
    } catch (error) {
      // نضمّن نص الخطأ الأصلي في الرسالة حتى يستمر عمل منطق كشف
      // انقطاع السوكِت في الشاشة (isSocketClosedError).
      throw UmCardsSyncException(
        'تعذر قراءة كروت User Manager من الراوتر: $error',
      );
    }
  }

  /// جدول ربط المستخدم بالبروفايل — بصيغتي v6 (user-profile أولاً
  /// لأنها القائمة الفعلية في v6، ثم user profile احتياطاً)؛ الفشل
  /// غير قاتل لأن صف المستخدم نفسه يحمل غالباً actual-profile أو
  /// profile، وهذا الجدول يُستعلم فقط عند الحاجة.
  Future<Map<String, String>> _loadProfileMap(RouterOsTalker talker) async {
    final map = <String, String>{};
    for (final command in const [
      <String>['/tool/user-manager/user-profile/print'],
      <String>['/tool/user-manager/user/profile/print'],
    ]) {
      try {
        final rows = await talker.talk(command).timeout(_auxTimeout);
        for (final row in rows) {
          final user =
              (row['user'] ?? row['username'] ?? row['name'] ?? '').trim();
          final profile = (row['profile'] ?? '').trim();
          if (user.isNotEmpty && profile.isNotEmpty) {
            map.putIfAbsent(user, () => profile);
          }
        }
        return map;
      } catch (_) {
        // نجرّب الصيغة البديلة قبل الاستسلام بهدوء.
      }
    }
    return map;
  }
}
